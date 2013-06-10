
module Profit

  class MessageHandler

    include EM::Deferrable

    attr_reader :text

    def initialize(json, conn)
      @json, @conn = (json || "{}"), conn
    end

    def run
      message_hash = JSON.parse(@json)
      metric_type = message_hash.delete("metric_type")
      key = "profit:metric:#{metric_type}"
      response = @conn.rpush key, message_hash.to_json
      if response == "OK"
        succeed response
      else
        fail response
      end
    end
  end
end
