module RequestQueueTime
  class Railtie < Rails::Railtie
    initializer "RequestQueueTime.request_middleware" do |app|
      app.middleware.insert_before Rack::Runtime, RequestQueueTime::Middleware
    end
  end
end
