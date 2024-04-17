# RequestQueueTime::Middleware

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/request_queue_time/middleware`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

The following environment variables are required:

```rb
    ENV["APP_NAME"]
    ENV["SERVER_ENVIRONMENT"]
```

For the Reporter to run, you need to have the following flag set as well:

```rb
    ENV["ECS_SETUP"]
```

If you want statsd measurements you need to have a the constant `StatsdDdog` defined.

Add the middleware to your middlerwares like so:

```rb
    Rails.configuration.middleware.insert_before 0, RequestQueueTimeMiddleware
```

And add the following to the application reloader:

```rb
Rails.application.reloader.to_prepare do
...
  AutoScalingMetrics::SidekiqReporter.enable if ENV["ECS_SETUP"]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bjonord/request-queue-time-middleware. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Request::Queue::Time::Middleware project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bjonord/request-queue-time-middleware/blob/master/CODE_OF_CONDUCT.md).
