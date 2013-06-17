require 'sinatra'
require 'profit'
require 'redis'
require 'json'

class ChartApp < Sinatra::Application

  include Profit

  get '/?' do
    data = Hash.new([])
    Key.all.each do |key|
      data[key.to_s] = key.metrics.map { |metric| metric.point }
    end

    erb :index, locals: { data: data }
  end
end
