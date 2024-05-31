module RequestQueueTime
  module AutoScalingMetrics
    class SidekiqReporter
      def self.enable
        Sidekiq.configure_server do |config|
          config.on(:leader) do
            AutoScalingMetrics::Reporter.start do |reporter|
              reporter.collector = method(:collect_metrics)
            end
          end
        end
      end

      def self.collect_metrics
        Sidekiq::Queue.all.each do |queue|
          AutoScalingMetrics::Reporter.add_metric(
            metric_name: "sidekiq_queue_latency",
            value: queue.latency,
            unit: "Seconds",
            dimensions: [{name: "queue_name", value: queue.name}]
          )
        end
      end
    end
  end
end
