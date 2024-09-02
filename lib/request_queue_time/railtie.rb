module RequestQueueTime
  class Railtie < Rails::Railtie
    initializer "RequestQueueTime.request_middleware" do |app|
      app.middleware.insert_before 0, RequestQueueTime::Middleware
    end
  end
end
