require 'zmq'
require 'eventmachine'
require 'em-hiredis'
require 'json'
require 'logger'
require 'active_support/hash_with_indifferent_access'

module Profit

  class << self

    attr_accessor :redis_host, :redis_port

    def redis
      @redis ||= Redis.new(host: redis_host, port: redis_port)
    end
  end
end

require 'profit/server'
require 'profit/client'
require 'profit/metric'
require 'profit/key'
