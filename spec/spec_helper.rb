require "dotenv"
Dotenv.load(".env.test")

require "bundler/setup"
require_relative "support/time_helper"

require "request_queue_time/middleware"
require "rails"
require "sidekiq/api"

RSpec.configure do |config|
  Rails.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include ActiveSupport::Testing::TimeHelpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
