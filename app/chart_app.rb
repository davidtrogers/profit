require 'sinatra'

class ChartApp < Sinatra::Application

  get '/' do
    erb :index
  end
end
