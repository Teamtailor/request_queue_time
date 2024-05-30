module RequestQueueTime
  class Railtie < Rails::Railtie
    initializer "request_queue_time.configure_rails_initialization" do |app|
      app.middleware.insert_before 0, RequestQueueTime::Middleware
    end
  end
end
