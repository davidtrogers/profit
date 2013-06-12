module Profit

  def self.client
    @client ||= Client.new
  end

  class Client

    attr_accessor :ctx, :socket, :pending

    def initialize(options = {})
      @ctx            = options[:ctx]            || ZMQ::Context.new
      @server_address = options[:server_address] || "tcp://127.0.0.1:5556"
      @pending = {}
    end

    def start(metric_type)
      now = Time.now
      start_file = caller[0][/(.+):(.+):/,1]
      start_line = caller[0][/(.+):(.+):/,2].to_i + 1

      # TODO: wrap in a Mutex & make the key a combo of metric_type,
      #       pid, and/or thread object_id to make this thread safe and
      #       thread-robust.
      @pending[key_for(metric_type)] = { start_file: start_file,
                                         start_line: start_line,
                                         start_time: now }
    end

    def stop(metric_type)
      now = Time.now
      metric = @pending.delete key_for(metric_type)
      recorded_time = Time.now - metric[:start_time]
      stop_file = caller[0][/(.+):(.+):/,1]
      stop_line = caller[0][/(.+):(.+):/,2].to_i - 1

      socket.send({ metric_type: metric_type,
                    recorded_time: recorded_time,
                    start_file: metric[:start_file],
                    start_line: metric[:start_line],
                    stop_file: stop_file,
                    stop_line: stop_line }.to_json)
    end

    def socket
      Thread.current[:socket] ||= @ctx.connect(:PUSH, @server_address)
    end

    private

    def key_for(metric_type)
      "#{metric_type}:#{Thread.current.object_id}"
    end
  end
end
