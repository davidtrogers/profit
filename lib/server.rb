module Profit

  class Server

    attr_reader :ctx

    def initialize
      @ctx = ZMQ::Context.new
    end

    def shutdown!
      @shutdown = true
    end

    def setup_trap_int
      trap :INT do
        puts "\nSIGINT received, quitting!"
        EM.stop
      end
    end

    def run
      @run = true
      EM.run do

        @redis_pool = EM::Pool.new
        spawn = lambda { @redis_pool.add Redis.new(host: "127.0.0.1", port: 6379) }
        @redis_pool.on_error { |conn| spawn[] }
        10.times { spawn[] }

        @puller = @ctx.bind(:PULL, "tcp://127.0.0.1:5556")

        # gives us a graceful exit
        setup_trap_int

        if @shutdown
          EM.next_tick do # change to add_timer(1) for more delay
            @run = false
          end
        end

        # allows us to break out of the loop
        EM.add_periodic_timer do
          unless @run
            EM.stop unless @run
          end
        end

        # ensures we can continue to run other specs
        EM.add_shutdown_hook { puts("destroy"); @ctx.destroy }

        # this is the entry to message handling
        EM.add_periodic_timer do
          @redis_pool.perform do |conn|
            message_handler = MessageHandler.new @puller.recv, conn

            message_handler.callback do |response|
              puts response.inspect
            end
            message_handler.run
            message_handler
          end
        end
      end
    end
  end
end
