require "request_queue_time/middleware/version"
require "services/auto_scaling_metrics"

module RequestQueueTime
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      metrics = Metrics.new(env)

      AutoScalingMetrics::Reporter.start if ENV["ECS_SETUP"]

      unless metrics.ignore?
        tags = ["request_method:#{env["REQUEST_METHOD"]}"]
        if Object.const_defined?(:StatsdDog)
          StatsdDdog.timing("rails.request.queue_time", metrics.queue_time, tags:)
          StatsdDdog.timing("rails.request.queue_time.network_time", metrics.network_time, tags:)
        end

        env["request_queue_time"] = metrics.queue_time
        env["request_network_time"] = metrics.network_time

        if ENV["ECS_SETUP"]
          AutoScalingMetrics::Reporter.instance.track_request_queue_time(metrics.queue_time)
        end
      end

      @app.call(env)
    end

    class Metrics
      MILLISECONDS_CUTOFF = Time.new(2000, 1, 1).to_i * 1000
      MICROSECONDS_CUTOFF = MILLISECONDS_CUTOFF * 1000
      NANOSECONDS_CUTOFF = MICROSECONDS_CUTOFF * 1000
      REQUEST_SIZE_LIMIT_BYTES = 100_000

      attr_reader :network_time, :request_start, :now, :request_size

      def initialize(env)
        @network_time = env["puma.request_body_wait"].to_i
        @request_start = env["HTTP_X_REQUEST_START"]
        @now = Time.now
        @request_size = env["rack.input"].respond_to?(:size) ? env["rack.input"].size : 0
      end

      def ignore?
        queue_time.nil? || request_size > REQUEST_SIZE_LIMIT_BYTES
      end

      def queue_time
        return @queue_time if defined?(@queue_time)

        start = started_at
        return if start.nil?

        queue_time = ((now - start) * 1000).to_i

        # Remove the time Puma was waiting for the request body.
        queue_time -= network_time

        @queue_time = (queue_time > 0) ? queue_time : 0
      end

      def started_at
        if request_start
          # There are several variants of this header. We handle these:
          #   - whole milliseconds (Heroku)
          #   - whole microseconds (???)
          #   - whole nanoseconds (Render)
          #   - fractional seconds (NGINX)
          #   - preceeding "t=" (NGINX)
          value = request_start.gsub(/[^0-9.]/, "").to_f

          # `value` could be seconds, milliseconds, microseconds or nanoseconds.
          # We use some arbitrary cutoffs to determine which one it is.

          if value > NANOSECONDS_CUTOFF
            Time.at(value / 1_000_000_000.0)
          elsif value > MICROSECONDS_CUTOFF
            Time.at(value / 1_000_000.0)
          elsif value > MILLISECONDS_CUTOFF
            Time.at(value / 1000.0)
          else
            Time.at(value)
          end
        end
      end
    end
  end
end
