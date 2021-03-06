require 'spec_helper'

describe Profit::Client do

  let!(:redis)         { Redis.new(host: "127.0.0.1", port: 6379) }
  let!(:client)        { Profit::Client.new(ctx: server.ctx) }
  let!(:server)        { TestServer.server }
  let!(:server_thread) { TestServer.server_thread }

  after do
    redis.del("profit:metric:some_foo_measurement")
    redis.del("profit:keys")
  end

  it "sends the amount of time it takes to run some code" do
    metrics = redis.lrange("profit:metric:some_foo_measurement", 0, -1)
    expect(metrics).to be_empty

    client.start("some_foo_measurement")
    sleep 1
    client.stop("some_foo_measurement")

    server_thread.join(0.1)

    metrics = redis.lrange("profit:metric:some_foo_measurement", 0, -1)
    metric = JSON.parse(metrics.first)
    expect(metric['recorded_time']).to be_within(0.1).of(1)
  end

  it "sends the unix time of when the measurement started" do
    metrics = redis.lrange("profit:metric:some_foo_measurement", 0, -1)
    expect(metrics).to be_empty

    client.start("some_foo_measurement")
    now = Time.now
    sleep 1
    client.stop("some_foo_measurement")

    server_thread.join(0.1)

    metrics = redis.lrange("profit:metric:some_foo_measurement", 0, -1)
    metric = JSON.parse(metrics.first)
    expect(metric['start_time']).to be_within(1).of(now.to_i)
  end

  describe "Profit.client" do

    it "creates a single client instance" do
      expect(Profit.client(ctx: server.ctx)).to be_a(Profit::Client)
    end
  end

  describe "#ctx" do

    it "is a ZMQ context" do
      expect(client.ctx).to be_a(ZMQ::Context)
    end
  end

  describe "#new" do

    it "connects to an open socket on a Profit::Server" do
      expect(client.ctx).to be_a(ZMQ::Context)

      expect(client.socket).to be_a(ZMQ::Socket)
      expect(client.socket.to_s).to eq "PUSH socket connected to tcp://127.0.0.1:5556"
    end

    it "sends an initial message to notify the server of itself"
  end

  describe "#pending" do

    it "is a Hash" do
      expect(client.pending).to be_a(Hash)
    end
  end

  describe "#start" do

    it "starts the timer" do
      expect(client.pending).to be_empty

      client.start("some_foo_measurement")
      now = Time.now

      key = client.pending.keys.grep(/some_foo_measurement/).first
      pending_metric = client.pending[key]
      expect(pending_metric.start_time.to_i).to be_within(1).of(now.to_i)
    end

    it "records where the execution starts" do
      expect(client.pending).to be_empty

      client.start("some_foo_measurement")
      start_line = __LINE__

      key = client.pending.keys.grep(/some_foo_measurement/).first
      pending_metric = client.pending[key]
      expect(pending_metric.start_line).to match(%r{#{__FILE__}:#{start_line - 1}})
    end
  end

  describe "#stop" do

    after do
      redis.del("profit:metric:m_1")
      redis.del("profit:metric:m_2")
    end

    it "matches up with the start marker" do
      client.start("m_1")
      expect(client.pending.keys.count).to eq 1
      sleep 0.3
      client.start("m_2")
      expect(client.pending.keys.count).to eq 2
      sleep 1
      client.stop("m_1")
      client.start("m_1")
      expect(client.pending.keys.count).to eq 2
      sleep 0.2
      client.stop("m_2")
      expect(client.pending.keys.count).to eq 1
      client.stop("m_1")

      server_thread.join(0.1)

      first_measurement_list = redis.lrange("profit:metric:m_1", 0, -1)
      second_measurement_list = redis.lrange("profit:metric:m_2", 0, -1)

      expect(first_measurement_list.count).to eq 2
      expect(second_measurement_list.count).to eq 1

      expect(JSON.parse(first_measurement_list[0])['recorded_time']).to be_within(0.1).of(0.2)
      expect(JSON.parse(first_measurement_list[1])['recorded_time']).to be_within(0.1).of(1.3)
      expect(JSON.parse(second_measurement_list[0])['recorded_time']).to be_within(0.1).of(1.2)
    end

    it "records where the execution stops" do
      client.start("m_1")
      sleep 0.1
      stop_line = __LINE__
      client.stop("m_1")

      server_thread.join(0.1)

      measurements = redis.lrange("profit:metric:m_1", 0, -1)
      metric = JSON.parse(measurements[0])
      expect(metric['stop_line']).to match(%r{#{__FILE__}:#{stop_line + 1}})
    end
  end
end
