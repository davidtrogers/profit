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

    def run
      EM.run do

        # startup the EM::Hiredis connections
        spawn_redis_connections

        # gives us a graceful exit
        setup_interrupt_handling

        # this is the entry to message handling
        EM.add_periodic_timer do

          # blocking ZMQ socket
          message = puller.recv || ""

          # take a worker from the pool to save the metric to Redis
          redis_pool.perform do |conn|

            message_hash = JSON.parse(message)
            metric_type  = message_hash.delete("metric_type")

            response     = conn.rpush "profit:metric:#{metric_type}", message_hash.to_json
            response.callback { |resp| puts "callback: #{resp}"}
            response.errback  { |resp| puts "errback: #{resp}"}
            response
          end
        end
      end
    end

    private

    def setup_interrupt_handling
      trap(:INT) { EM.stop }
      EM.add_shutdown_hook { ctx.destroy }
    end

    def spawn_redis_connections
      spawn = lambda { redis_pool.add(EM::Hiredis.connect(redis_address)) }
      redis_pool.on_error { |conn| spawn[] }
      @options[:pool_size].times { spawn[] }
    end

    def puller
      @puller ||= ctx.bind(:PULL, @options[:zmq_address])
    end

    def redis_pool
      @redis_pool ||= EM::Pool.new
    end

    def redis_address
      "redis://#{@options[:redis_address]}:#{@options[:redis_port]}/"
    end
  end
end
