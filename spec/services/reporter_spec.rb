# frozen_string_literal: true

require "spec_helper"

RSpec.describe RequestQueueTime::AutoScalingMetrics::Reporter do
  let(:subject) { described_class.instance }

  before do
    described_class.start
  end

  after do
    described_class.instance.stop!
  end

  describe "#track_request_queue_time", :freeze_time do
    it "adds a metric to the buffer with the correct name, value, and unit" do
      subject.track_request_queue_time(42)

      expect(subject.instance_variable_get(:@buffer).pop).to eq(
        metric_name: "request_queue_time",
        value: 42,
        unit: "Milliseconds",
        timestamp: Time.now,
        dimensions: [
          {name: "service", value: ENV["DD_SERVICE"]},
          {name: "environment", value: ENV["DD_ENV"]}
        ]
      )
    end
  end

  describe "buffer flushing", :freeze_time do
    it "flushes the buffer to CloudWatch when it reaches the buffer size limit" do
      subject.stop!
      allow(subject).to receive(:loop) do |&blk|
        blk.call
      end
      allow(subject).to receive(:sleep).and_return(true)
      allow(subject).to receive(:should_flush?).and_return(true)

      expect_any_instance_of(Aws::CloudWatch::Client).to receive(:put_metric_data).with(
        namespace: "Teamtailor/queue_times",
        metric_data: [
          {
            metric_name: "request_queue_time",
            dimensions: [
              {name: "service", value: ENV["DD_SERVICE"]},
              {name: "environment", value: ENV["DD_ENV"]}
            ],
            timestamp: Time.now,
            value: 42,
            unit: "Milliseconds"
          }
        ]
      )

      thread = subject.start!
      subject.track_request_queue_time(42)
      thread.join
    end

    it "flushes the buffer to CloudWatch when the flush interval has elapsed" do
      subject.stop!
      allow(subject).to receive(:loop) do |&blk|
        blk.call
      end
      allow(subject).to receive(:sleep).and_return(true)
      expect(subject).to receive(:should_flush?).and_return(true)

      expect_any_instance_of(Aws::CloudWatch::Client).to receive(:put_metric_data).with(
        namespace: "Teamtailor/queue_times",
        metric_data: [
          {
            metric_name: "request_queue_time",
            dimensions: [
              {name: "service", value: ENV["DD_SERVICE"]},
              {name: "environment", value: ENV["DD_ENV"]}
            ],
            timestamp: Time.now,
            value: 42,
            unit: "Milliseconds"
          }
        ]
      )

      thread = subject.start!
      subject.track_request_queue_time(42)
      thread.join
    end

    it "does not flush the buffer to CloudWatch when it is empty" do
      allow(subject).to receive(:should_flush?).and_return(true)

      expect_any_instance_of(Aws::CloudWatch::Client).not_to receive(:put_metric_data)

      subject.track_request_queue_time(42)
    end

    it "does not flush the buffer to CloudWatch when it has not reached the buffer size limit or the flush interval has not elapsed" do
      allow(subject).to receive(:should_flush?).and_return(false)

      expect_any_instance_of(Aws::CloudWatch::Client).not_to receive(:put_metric_data)

      subject.track_request_queue_time(42)
    end

    describe "collector" do
      it "triggers the collector" do
        subject.stop!

        allow(subject).to receive(:loop) do |&blk|
          blk.call
          blk.call
          blk.call
        end
        allow(subject).to receive(:sleep).and_return(true)
        allow(subject).to receive(:should_flush?).and_return(true)

        collector = double("collector", call: true)
        subject.collector = collector
        expect(collector).to receive(:call).exactly(3).times

        subject.start!.join
      end
    end
  end
end
