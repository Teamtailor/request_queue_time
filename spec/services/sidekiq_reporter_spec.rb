# frozen_string_literal: true

require "spec_helper"

RSpec.describe AutoScalingMetrics::SidekiqReporter do
  describe ".enable" do
    it "starts the reporter and collects metrics" do
      expect(Sidekiq).to receive(:configure_server).and_yield(config = double)
      expect(config).to receive(:on).with(:leader).and_yield
      expect(AutoScalingMetrics::Reporter).to receive(:start).and_yield(reporter = double)
      expect(reporter).to receive(:collector=).with(described_class.method(:collect_metrics))

      described_class.enable
    end
  end

  describe ".collect_metrics" do
    it "adds a metric for each Sidekiq queue" do
      queue1 = double(name: "queue1", latency: 10)
      queue2 = double(name: "queue2", latency: 20)
      allow(Sidekiq::Queue).to receive(:all).and_return([queue1, queue2])

      expect(AutoScalingMetrics::Reporter).to receive(:add_metric).with(
        metric_name: "sidekiq_queue_latency",
        value: 10,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "queue1"}]
      )
      expect(AutoScalingMetrics::Reporter).to receive(:add_metric).with(
        metric_name: "sidekiq_queue_latency",
        value: 20,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "queue2"}]
      )

      described_class.collect_metrics
    end
  end
end
