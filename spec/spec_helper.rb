require './lib/profit'
require './app/chart_app'
require 'redis'
require 'capybara'
require 'capybara/dsl'

set :environment, :test

class TestServer

  def self.server
    @@server ||= Profit::Server.new
  end

  def self.server_thread
    @@server_thread ||= Thread.new { server.run }
  end
end

Capybara.app = ChartApp

RSpec.configure do |config|

  config.before(:suite) do
    TestServer.server
  end

  config.after(:suite) do
    TestServer.server_thread.join(1)
  end

  config.include Rack::Test::Methods
  config.include Capybara::DSL
end
