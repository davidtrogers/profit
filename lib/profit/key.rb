module Profit

  class Key

    class << self

      def all
        redis.smembers("profit:keys").map { |key| new(key.split(":").last) }
      end

      def redis
        @redis ||= Redis.new(host: "127.0.0.1", port: 6379)
      end
    end

    def initialize(key)
      @key = key
    end

    def to_s
      @key
    end

    def metrics
      self.class.redis.lrange(full, 0, -1).map {|key_data| Metric.new(key_data)}.reverse
    end

    def full
      "profit:metric:#{@key}"
    end
  end
end
