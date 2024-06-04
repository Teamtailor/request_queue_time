lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "request_queue_time/middleware/version"

Gem::Specification.new do |spec|
  spec.name = "request_queue_time"
  spec.version = RequestQueueTime::Middleware::VERSION
  spec.authors = ["Jonas Brusman", "Björn Nordstrand"]
  spec.homepage = "https://github.com/teamtailor/request_queue_time"
  spec.summary = "Used by ECS stacks for Teamtailor"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/teamtailor/request_queue_time"
  spec.metadata["changelog_uri"] = "https://github.com/teamtailor/request_queue_time/blob/main/CHANGELOG.md"
  spec.metadata["github_repo"] = "ssh://github.com/teamtailor/request_queue_time"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-cloudwatch"
  spec.add_dependency "dogstatsd-ruby"

  spec.add_development_dependency "bundler", "~> 2.4"
end
