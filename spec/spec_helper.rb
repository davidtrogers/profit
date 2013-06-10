require './lib/profit'

class TestServer

  def self.server
    @@server ||= Profit::Server.new
  end

  def self.server_thread
    @@server_thread ||= Thread.new { server.run }
  end
end

RSpec.configure do |config|

  config.before(:suite) do
    TestServer.server
  end

  config.after(:suite) do
    TestServer.server_thread.join(1)
  end
end
