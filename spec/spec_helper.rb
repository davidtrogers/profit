require './lib/profit'
require './lib/profit/app/chart_app'
require 'redis'
require 'capybara'
require 'capybara/dsl'
require 'capybara/rspec'
require 'capybara/webkit'

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
Capybara.javascript_driver = :webkit

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
