require 'spec_helper'

describe Profit::Server do

  let!(:redis) { Redis.new(host: "127.0.0.1", port: 6379) }

  after do
    redis.del("some_slow_piece_of_code")
  end

  it "stores metrics messages" do
    server = Profit::Server.new
    pusher = server.ctx.connect(:PUSH, "tcp://127.0.0.1:5556")

    pusher.send({ recorded_time: (now = Time.now),
                  total_time: 12.012,
                  metric_type: "some_slow_piece_of_code",
                  start_line: 1,
                  end_line: 42,
                  start_file: "/foo/bar/baz.rb",
                  end_file: "/foo/bar/biz.rb" }.to_json)
    server.shutdown! # kill the server after first message
    server.run

    list = redis.lrange("some_slow_piece_of_code", 0, -1)
    expect(list.count).to eq 1
    expect(redis.llen("some_slow_piece_of_code")).to eq 1

    metric = JSON.parse(list[0])
    expect(metric["total_time"]).to eq 12.012
    expect(metric["start_line"]).to eq 1
    expect(metric["end_line"]).to eq 42
    expect(metric["start_file"]).to eq "/foo/bar/baz.rb"
    expect(metric["end_file"]).to eq "/foo/bar/biz.rb"
    expect(metric["recorded_time"]).to eq now.to_s
  end

  it "kills the zmq context with a shutdown hook" do
    server = Profit::Server.new
    pusher = server.ctx.connect(:PUSH, "tcp://127.0.0.1:5556")
    pusher.send("") # need to send one message to break out of socket
    server.shutdown!
    server.run

    expect { server.ctx.destroy }.to raise_error(ZMQ::Error)
  end

  it "traps INT and shuts down gracefully"
  it "stores no more than 5_000 metrics in the list"
end
