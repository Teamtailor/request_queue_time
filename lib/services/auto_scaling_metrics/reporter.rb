# Copyright 2024 Judoscale
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "aws-sdk-cloudwatch"
require "singleton"

module AutoScalingMetrics
  class Reporter
    include Singleton

    DIMENSIONS = [
      {name: "service", value: ENV["APP_NAME"]},
      {name: "environment", value: ENV["SERVER_ENVIRONMENT"]}
    ]

    attr_accessor :collector

    def self.start(&)
      return false if instance.started?

      instance.start!(&)
    end

    def self.stop
      return unless instance.started?
      instance.stop!
    end

    def start!(&block)
      Rails.logger.info "Starting AutoScalingMetrics::Reporter"
      @interval = 30
      @buffer = Queue.new
      @buffer_size_limit = 1000
      @cloudwatch = Aws::CloudWatch::Client.new
      @last_flush_time = Time.now
      @pid = Process.pid

      yield self if block

      start_flush_thread
    end

    def started?
      @pid == Process.pid
    end

    def stop!
      @_thread&.terminate
      @_thread = nil
      @pid = nil
    end

    def track_request_queue_time(time)
      add_metric(metric_name: "request_queue_time", value: time, unit: "Milliseconds", timestamp: Time.now)
    end

    def self.add_metric(metric)
      instance.add_metric(metric)
    end

    def add_metric(metric)
      metric[:dimensions] = (metric[:dimensions] || []) + DIMENSIONS
      @buffer << metric
    end

    private

    def start_flush_thread
      @_thread = Thread.new do
        Thread.current.name = "auto_scaling_metrics.#{@pid}"

        loop do
          if should_flush?
            collector&.call
            flush_metrics
          end
        rescue => ex
          Sentry.capture_exception(ex)
        ensure
          sleep(1)
        end
      end
    end

    def should_flush?
      @buffer.size >= @buffer_size_limit || (Time.now - @last_flush_time) >= @interval
    end

    def flush_metrics
      metrics_to_flush = []
      metrics_to_flush << @buffer.pop until @buffer.empty?

      unless metrics_to_flush.empty?
        put_metrics_to_cloudwatch(metrics_to_flush)
        @last_flush_time = Time.now
      end
    end

    def put_metrics_to_cloudwatch(metrics)
      return if Rails.env.development?

      @cloudwatch.put_metric_data(
        namespace: "Teamtailor/queue_times",
        metric_data: metrics.take(1000)
      )
    end
  end
end
