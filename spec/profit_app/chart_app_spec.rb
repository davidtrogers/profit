require 'spec_helper'

describe 'Chart App' do

  let!(:redis)         { Redis.new(host: "127.0.0.1", port: 6379) }
  let!(:client)        { Profit::Client.new(ctx: server.ctx) }
  let!(:server)        { TestServer.server }
  let!(:server_thread) { TestServer.server_thread }

  after do
    redis.del("profit:metric:some_foo_metric")
    redis.del("profit:keys")
  end

  it "has section links for each metric key" do
    visit '/'

    expect(page).to_not have_link("some_foo_metric")

    client.start("some_foo_metric")
    sleep 0.1
    client.stop("some_foo_metric")

    visit '/'

    expect(page).to have_link("some_foo_metric")
  end
end
