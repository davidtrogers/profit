module Profit

  class Server

    attr_reader :ctx

    def initialize(options = {})
      @options = {}
      @options[:redis_address] = options[:redis_address] || "127.0.0.1"
      @options[:redis_port]    = options[:redis_port]    || 6379
      @options[:zmq_address]   = options[:zmq_address]   || "tcp://*:5556"
      @options[:pool_size]     = options[:pool_size]     || 10
      @ctx = ZMQ::Context.new
    end

    def setup_trap_int
      trap :INT do
        puts "\nSIGINT received, quitting!"
        EM.stop
      end

      EM.add_shutdown_hook { @ctx.destroy }
    end

    def run
      EM.run do
        @redis_pool = EM::Pool.new
        spawn = lambda do
          @redis_pool.add EM::Hiredis.connect("redis://#{@options[:redis_address]}:#{@options[:redis_port]}/")
        end
        @redis_pool.on_error { |conn| spawn[] }
        @options[:pool_size].times { spawn[] }

        @puller = @ctx.bind(:PULL, @options[:zmq_address])

        # gives us a graceful exit
        setup_trap_int

        # this is the entry to message handling
        EM.add_periodic_timer do
          message = @puller.recv || ""
          @redis_pool.perform do |conn|
            message_hash = JSON.parse(message)
            metric_type  = message_hash.delete("metric_type")
            response = conn.rpush "profit:metric:#{metric_type}", message_hash.to_json
            response.callback { |resp| puts "callback: #{resp}"}
            response.errback  { |resp| puts "errback: #{resp}"}
            response
          end
        end
      end
    end
  end
end
