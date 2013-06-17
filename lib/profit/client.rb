module Profit

  def self.client(options = {})
    @client ||= Client.new(options)
  end

  class Client

    attr_accessor :ctx, :pending

    def initialize(options = {})
      @ctx            = options[:ctx]            || ZMQ::Context.new
      @server_address = options[:server_address] || "tcp://127.0.0.1:5556"
      @pending        = {}
    end

    def start(metric_key)
      pending_key = pending_key_for(Key.new(metric_key).to_s)
      metric      = Metric.new(metric_key: metric_key,
                               start_line: caller[0],
                               start_time: Time.now)

      pending[pending_key] = metric
    end

    def stop(metric_key)
      pending_key          = pending_key_for(Key.new(metric_key).to_s)
      metric               = pending.delete pending_key
      metric.recorded_time = Time.now - metric.start_time
      metric.stop_line     = caller[0]

      socket.send(metric.to_json)
    end

    def socket
      Thread.current[:socket] ||= @ctx.connect(:PUSH, @server_address)
    end

    private

    def pending_key_for(metric_type)
      "#{metric_type}:#{Thread.current.object_id}"
    end
  end
end
