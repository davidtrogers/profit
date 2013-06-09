
module Profit

  class MessageHandler

    include EM::Deferrable

    attr_reader :text

    def initialize(json, conn)
      @json, @conn = json, conn
    end

    def run
      return succeed("Starting") if @json.empty?
      message_hash = JSON.parse(@json)
      key = message_hash.delete("metric_type")
      response = @conn.rpush key, message_hash.to_json
      if response == "OK"
        succeed response
      else
        fail response
      end
    end
  end
end
