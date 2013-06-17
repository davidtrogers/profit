require 'sinatra'
require 'profit'
require 'redis'
require 'json'

class ChartApp < Sinatra::Application

  include Profit

  def self.options=(options)
    settings.port       = options[:sinatra_port] || 4567
    Profit.redis_host   = options[:redis_host]   || "127.0.0.1"
    Profit.redis_port   = options[:redis_port]   || 6379
    puts "Connecting to Redis: #{Profit.redis_host}:#{Profit.redis_port}"
  end

  get '/?' do
    data = Hash.new([])
    Key.all.each do |key|
      data[key.to_s] = key.metrics.map { |metric| metric.point }
    end

    erb :index, locals: { data: data }
  end
end
