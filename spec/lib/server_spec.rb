require 'spec_helper'

describe Profit::Server do

  let!(:redis)         { Redis.new(host: "127.0.0.1", port: 6379) }
  let!(:server)        { TestServer.server }
  let!(:server_thread) { TestServer.server_thread }

  after do
    redis.del("profit:metric:some_slow_piece_of_code")
    redis.del("profit:keys")
  end

  it "stores metrics messages" do
    pusher = server.ctx.connect(:PUSH, "tcp://127.0.0.1:5556")

    pusher.send({ recorded_time: (now = Time.now),
                  total_time: 12.012,
                  metric_key: "some_slow_piece_of_code",
                  start_line: 1,
                  end_line: 42,
                  start_file: "/foo/bar/baz.rb",
                  end_file: "/foo/bar/biz.rb" }.to_json)
    server_thread.join(0.1)

    list = redis.lrange("profit:metric:some_slow_piece_of_code", 0, -1)
    expect(list.count).to eq 1
    expect(redis.llen("profit:metric:some_slow_piece_of_code")).to eq 1

    metric = JSON.parse(list[0])
    expect(metric["total_time"]).to eq 12.012
    expect(metric["start_line"]).to eq 1
    expect(metric["end_line"]).to eq 42
    expect(metric["start_file"]).to eq "/foo/bar/baz.rb"
    expect(metric["end_file"]).to eq "/foo/bar/biz.rb"
    expect(metric["recorded_time"]).to eq now.to_s
  end

  it "stores a set of all metric keys" do
    pusher = server.ctx.connect(:PUSH, "tcp://127.0.0.1:5556")

    pusher.send({ recorded_time: (now = Time.now),
                  total_time: 12.012,
                  metric_key: "some_slow_piece_of_code",
                  start_line: 1,
                  end_line: 42,
                  start_file: "/foo/bar/baz.rb",
                  end_file: "/foo/bar/biz.rb" }.to_json)

    pusher.send({ recorded_time: (now = Time.now),
                  total_time: 14.316,
                  metric_key: "some_slow_piece_of_code",
                  start_line: 1,
                  end_line: 42,
                  start_file: "/foo/bar/baz.rb",
                  end_file: "/foo/bar/biz.rb" }.to_json)

    pusher.send({ recorded_time: (now = Time.now),
                  total_time: 1.455,
                  metric_key: "other_piece_of_code",
                  start_line: 12,
                  end_line: 23,
                  start_file: "/foo/bar/baz.rb",
                  end_file: "/foo/bar/biz.rb" }.to_json)
    server_thread.join(0.1)

    set = redis.smembers("profit:keys")
    expect(set.count).to eq 2
    expect(set.to_a.sort).to eq ["profit:metric:other_piece_of_code",
                                 "profit:metric:some_slow_piece_of_code"]
  end

  it "limits messages to 100" do
    pusher = server.ctx.connect(:PUSH, "tcp://127.0.0.1:5556")

    102.times do |i|
      pusher.send({ recorded_time: (now = Time.now),
                    total_time: i,
                    metric_key: "some_slow_piece_of_code",
                    start_line: 1,
                    end_line: 42,
                    start_file: "/foo/bar/baz.rb",
                    end_file: "/foo/bar/biz.rb" }.to_json)
    end

    server_thread.join(1)

    expect(redis.llen("profit:metric:some_slow_piece_of_code")).to eq 100

    list = redis.lrange("profit:metric:some_slow_piece_of_code", 0, -1)
    expect(JSON.parse(list.last)['total_time']).to eq 2
    expect(JSON.parse(list.first)['total_time']).to eq 101
  end
end
