module RequestQueueTime
  module AutoScalingMetrics
    class SidekiqReporter
      # `required_queues` lists queue names that must always publish a datapoint,
      # even when Redis has no entry for them. Without this, a queue with a
      # CloudWatch autoscaling policy that never enqueues sits permanently in
      # INSUFFICIENT_DATA, blocking scale-in for the whole service.
      def self.enable(required_queues: [])
        Sidekiq.configure_server do |config|
          config.on(:leader) do
            AutoScalingMetrics::Reporter.start do |reporter|
              reporter.collector = -> { collect_metrics(required_queues) }
            end
          end
        end
      end

      def self.collect_metrics(required_queues = [])
        live_queues = Sidekiq::Queue.all.to_h { |q| [q.name, q] }
        names = (required_queues + live_queues.keys).uniq

        names.each do |name|
          queue = live_queues[name]
          AutoScalingMetrics::Reporter.add_metric(
            metric_name: "sidekiq_queue_latency",
            value: (queue.nil? || queue.paused?) ? 0 : queue.latency,
            unit: "Seconds",
            dimensions: [{name: "queue_name", value: name}]
          )
        end
      end
    end
  end
end
