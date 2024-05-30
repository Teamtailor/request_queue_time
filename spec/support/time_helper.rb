require "active_support"
require "active_support/testing/time_helpers"

RSpec.configure do |config|
  config.around(:each, :freeze_time) do |example|
    freeze_time do
      example.run
    end
  end
end
