require 'spec_helper'

def current_path
  ["/", page.evaluate_script("document.location.href.split('/')").last].join
end

def active_link
  page.find("li.active a")
end

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

    Timeout.timeout(1) do
      sleep(0.01) until redis.smembers("profit:keys").any?
    end

    visit '/'

    expect(page).to have_link("some_foo_metric")
  end

  describe "urls", js: true do

    before do
      client.start("metric_1")
      sleep 0.1
      client.stop("metric_1")

      client.start("metric_2")
      sleep 0.1
      client.stop("metric_2")
    end

    it "changes the url based on the current tab" do
      visit "/"
      expect(active_link.text).to eq "metric_2"
      expect(current_path).to eq "/"

      click_link("metric_1")

      expect(active_link.text).to eq "metric_1"
      expect(current_url).to match(/\/\#metric_1/)

      click_link("metric_2")

      expect(active_link.text).to eq "metric_2"
      expect(current_url).to match(/\/\#metric_2/)
    end

    it "loads the tab according to the url's anchor" do
      visit "/#metric_1"

      expect(active_link.text).to eq "metric_1"

      # TODO: have to load the page twice for now, investigate cause
      visit "/#metric_2" and visit "/#metric_2"

      expect(active_link.text).to eq "metric_2"
    end
  end
end
