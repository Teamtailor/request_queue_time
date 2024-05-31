# RequestQueueTime::Middleware

This gem gives us an indication of the time that a request/job is spent waiting in line to be processed and with that gauge we scale our ECS cluster tasks up and down. A lot of the logic was borrowed from Judoscales ruby gem, but at the time of writing the code we were unable to utilise Judoscale on ECS, however now that the gem is being extracted this is something that is now a product that they offer. However we are unsure about the financial gains that can be gained from using the service, vs our own solution.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'request-queue-time-middleware'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install request-queue-time-middleware

## Usage

The following environment variables are required for the metric that is reported to cloudwatch:

```rb
    ENV["APP_NAME"]
    ENV["SERVER_ENVIRONMENT"]
```

For the Reporter to run, you need to have the following flag set as well:

```rb
    ENV["ECS_SETUP"]
```

If you want statsd measurements you need to have a the constant `StatsdDdog` defined.

A Railtie will insert the middleware first in your stack, but if there are issues or you need more control of the middleware placements you can use the configuration below:

```rb
    Rails.configuration.middleware.insert_before 0, RequestQueueTimeMiddleware
```

The following is required for the sidekiq portion to work though:
<!-- And add the following to the application reloader: -->

```rb
Rails.application.reloader.to_prepare do
...
  AutoScalingMetrics::SidekiqReporter.enable if ENV["ECS_SETUP"]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` or `bundle exec rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
