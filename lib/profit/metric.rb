module Profit

  class Metric

    attr_accessor :data,
                  :metric_key,
                  :recorded_time,
                  :start_line,
                  :start_time,
                  :stop_line

    def initialize(metric)
      @data = HashWithIndifferentAccess.new(metric.is_a?(String) ? JSON.parse(metric) : metric)
      @metric_key,
      @recorded_time,
      @start_line,
      @start_time,
      @stop_line = data.values_at(:metric_key,
                                  :recorded_time,
                                  :start_line,
                                  :start_time,
                                  :stop_line)
    end

    def to_json
      { metric_key: metric_key,
        recorded_time: recorded_time,
        start_line: start_line,
        start_time: start_time.to_i,
        stop_line: stop_line }.to_json
    end

    def point
      { recorded_time: recorded_time, start_time: start_time }
    end

    def display_start_time
      DateTime.strptime(start_time.to_s,'%s').strftime("%H:%M:%S")
    end
  end
end
