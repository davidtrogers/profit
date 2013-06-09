require 'zmq'
require 'eventmachine'
require 'debugger'
require 'redis'
require 'json'

module Profit
end

require './lib/message_handler'
require './lib/server'
require './lib/client'
