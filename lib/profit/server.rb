module Profit

  class Server

    attr_reader :ctx

    def initialize
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
        spawn = lambda { @redis_pool.add Redis.new(host: "127.0.0.1", port: 6379) }
        @redis_pool.on_error { |conn| spawn[] }
        10.times { spawn[] }

        @puller = @ctx.bind(:PULL, "tcp://127.0.0.1:5556")

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
