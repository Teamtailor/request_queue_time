require "request_queue_time/middleware"
require "services/auto_scaling_metrics"

module RequestQueueTime
end

if defined?(Rails)
  require "request_queue_time/railtie"
end
