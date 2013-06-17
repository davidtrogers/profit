module Profit

  describe Profit::Key do

    let!(:redis) { Redis.new(host: "127.0.0.1", port: 6379) }

    after do
      redis.del("profit:keys")
    end

    describe ".all" do

      it "retrieves keys from redis" do
        redis.sadd("profit:keys", "profit:metric:some_great_key")

        expect(Key.all.map(&:to_s)).to eq(%w{ some_great_key })
      end
    end

    describe "#to_s" do

      it "gets back what you put in" do
        expect(Key.new("some_great_key").to_s).to eq "some_great_key"
      end
    end

    describe "#metrics" do

      after do
        redis.del("profit:keys:some_metric")
      end

      it "returns the metrics associated with a key" do
        test_metric = { recorded_time: 0.402520,
                        start_time: 1371520170,
                        start_line: "/Users/me/foo.rb:20",
                        stop_line: "/Users/me/foo.rb:22" }
        expect(DateTime.strptime("1371520170",'%s').strftime("%H:%M:%S")).to eq "01:49:30"

        redis.rpush("profit:metric:some_metric", test_metric.to_json)

        key = Key.new("some_metric")
        metric = key.metrics.first
        expect(metric.recorded_time).to eq 0.402520
        expect(metric.start_time).to eq 1371520170
      end
    end

    describe "#full" do

      it "returns the full redis key" do
        expect(Key.new("some_foobar").full).to eq  "profit:metric:some_foobar"
      end
    end
  end
end
