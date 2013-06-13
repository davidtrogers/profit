module Profit

  class Server

    attr_reader :ctx

    def initialize(options = {})
      @options = {}
      @options[:redis_address] = options[:redis_address] || "127.0.0.1"
      @options[:redis_port]    = options[:redis_port]    || 6379
      @options[:zmq_address]   = options[:zmq_address]   || "tcp://*:5556"
      @options[:pool_size]     = options[:pool_size]     || 10
      @options[:log_path]      = options[:log_path]      || STDOUT
      @options[:log_level]     = options[:log_level]     || :error

      logger.level = log_level
      @ctx = ZMQ::Context.new
      logger.info "Starting profit_server with options: #{@options}"
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

            message_hash     = JSON.parse(message)
            metric_type      = message_hash.delete("metric_type")
            metric_key       = "profit:metric:#{metric_type}"
            add_key_response = conn.sadd("profit:keys", metric_key)
            add_key_response.callback { |resp| logger.debug "adding key callback: #{resp}"}
            add_key_response.errback  { |resp| logger.error "adding key error: #{resp}"}

            push_metric_response = conn.rpush metric_key, message_hash.to_json
            push_metric_response.callback { |resp| logger.debug "callback: #{resp}"}
            push_metric_response.errback  { |resp| logger.error "error: #{resp}"}
            push_metric_response
          end
        end
      end
    end

    private

    def logger
      @logger ||= Logger.new(@options[:log_path])
    end

    def log_level
      Logger.const_get(@options[:log_level].upcase)
    end

    def setup_interrupt_handling
      trap(:INT) do
        logger.debug "trap received, shutting down EM run loop."
        EM.stop
      end

      EM.add_shutdown_hook do
        logger.debug "destroying ZMQ context"
        ctx.destroy
      end
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
