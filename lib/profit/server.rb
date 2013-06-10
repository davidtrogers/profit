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
    end

    def run
      EM.run do
        @redis_pool = EM::Pool.new
        spawn = lambda do
          @redis_pool.add Redis.new(host: @options[:redis_address],
                                    port: @options[:redis_port])
        end
        @redis_pool.on_error { |conn| spawn[] }
        @options[:pool_size].times { spawn[] }

        @puller = @ctx.bind(:PULL, @options[:zmq_address])

        # gives us a graceful exit
        setup_trap_int

        # ensures we can continue to run other specs
        EM.add_shutdown_hook { @ctx.destroy }

        # this is the entry to message handling
        EM.add_periodic_timer do
          @redis_pool.perform do |conn|
            message_handler = MessageHandler.new @puller.recv, conn

            message_handler.run
            message_handler
          end
        end
      end
    end
  end
end
