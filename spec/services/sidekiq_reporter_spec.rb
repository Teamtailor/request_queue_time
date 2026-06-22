# frozen_string_literal: true

require "spec_helper"

RSpec.describe RequestQueueTime::AutoScalingMetrics::SidekiqReporter do
  describe ".enable" do
    it "starts the reporter and collects metrics" do
      expect(Sidekiq).to receive(:configure_server).and_yield(config = double)
      expect(config).to receive(:on).with(:leader).and_yield
      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:start).and_yield(reporter = double)
      expect(reporter).to receive(:collector=).with(an_instance_of(Proc))

      described_class.enable
    end

    it "passes required_queues through to the collector" do
      expect(Sidekiq).to receive(:configure_server).and_yield(config = double)
      expect(config).to receive(:on).with(:leader).and_yield
      collector = nil
      allow(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:start).and_yield(reporter = double)
      allow(reporter).to receive(:collector=) { |c| collector = c }

      described_class.enable(required_queues: %w[critical within_3_hours])

      allow(Sidekiq::Queue).to receive(:all).and_return([])
      expect(described_class).to receive(:collect_metrics).with(%w[critical within_3_hours]).and_call_original
      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:add_metric).twice
      collector.call
    end
  end

  describe ".collect_metrics" do
    it "adds a metric for each Sidekiq queue" do
      queue1 = double(name: "queue1", latency: 10, paused?: false)
      queue2 = double(name: "queue2", latency: 15, paused?: true)
      queue3 = double(name: "queue3", latency: 20, paused?: false)
      allow(Sidekiq::Queue).to receive(:all).and_return([queue1, queue2, queue3])

      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:add_metric).with(
        metric_name: "sidekiq_queue_latency",
        value: 10,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "queue1"}]
      )
      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:add_metric).with(
        metric_name: "sidekiq_queue_latency",
        value: 0,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "queue2"}]
      )
      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:add_metric).with(
        metric_name: "sidekiq_queue_latency",
        value: 20,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "queue3"}]
      )

      described_class.collect_metrics
    end

    it "emits 0 for required_queues that are absent from Redis" do
      live = double(name: "default", latency: 5, paused?: false)
      allow(Sidekiq::Queue).to receive(:all).and_return([live])

      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:add_metric).with(
        metric_name: "sidekiq_queue_latency",
        value: 5,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "default"}]
      )
      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:add_metric).with(
        metric_name: "sidekiq_queue_latency",
        value: 0,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "within_3_hours"}]
      )

      described_class.collect_metrics(%w[default within_3_hours])
    end

    it "deduplicates when a required queue is also live" do
      live = double(name: "critical", latency: 2, paused?: false)
      allow(Sidekiq::Queue).to receive(:all).and_return([live])

      expect(RequestQueueTime::AutoScalingMetrics::Reporter).to receive(:add_metric).once.with(
        metric_name: "sidekiq_queue_latency",
        value: 2,
        unit: "Seconds",
        dimensions: [{name: "queue_name", value: "critical"}]
      )

      described_class.collect_metrics(%w[critical])
    end
  end
end
