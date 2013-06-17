require 'spec_helper'

module Profit

  describe Profit::Metric do

    let(:test_data) do
      { metric_key: 'some_metric',
        recorded_time: 0.10051,
        start_line: "/Users/me/foo.rb:20",
        start_time: 1371420170,
        stop_line: "/Users/me/foo.rb:22" }
    end

    describe "#new" do

      it "accepts a json string or a hash to initialize" do
        with_hash = Metric.new(test_data)
        with_json = Metric.new(test_data.to_json)

        expect(with_hash).to be_a(Metric)
        expect(with_json).to be_a(Metric)
      end
    end

    describe "#data" do

      it "returns the hash with which it was initiliazed" do
        with_hash = Metric.new(test_data)
        with_json = Metric.new(test_data.to_json)

        expect(with_hash.data).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(with_json.data).to be_a(ActiveSupport::HashWithIndifferentAccess)

        expect(with_hash.data).to eq with_json.data
      end
    end

    describe "#display_start_time" do

      it "gives the time as %H:%M:%S" do
        metric = Metric.new(test_data.to_json)
        expect(metric.display_start_time).to eq "22:02:50"
      end
    end

    describe "#start_time" do

      it "gives the unix time the metric started" do
        metric = Metric.new(test_data.to_json)
        expect(metric.start_time).to eq 1371420170
      end
    end

    describe "#recorded_time" do

      it "gives the difference in time as a float" do
        metric = Metric.new(test_data.to_json)
        expect(metric.recorded_time).to eq 0.10051
      end
    end

    describe "#point" do

      it "returns the recorded_time and start_time" do
        metric = Metric.new(test_data.to_json)
        expect(metric.point).to eq({ recorded_time: metric.recorded_time,
                                     start_time: metric.start_time })
      end
    end

    describe "#start_line" do

      it "returns a string" do
        metric = Metric.new(test_data)
        expect(metric.start_line).to eq "/Users/me/foo.rb:20"
      end
    end

    describe "#stop_line" do

      it "returns a string" do
        metric = Metric.new(test_data)
        expect(metric.stop_line).to eq "/Users/me/foo.rb:22"
      end
    end

    describe "#metric_key" do

      it "returns the key name" do
        metric = Metric.new(test_data)
        expect(metric.metric_key).to eq "some_metric"
      end
    end

    describe "#to_json" do

      it "converts to a json string" do
        metric = Metric.new(test_data)
        expect(metric.to_json).to eq test_data.to_json
      end
    end
  end
end
