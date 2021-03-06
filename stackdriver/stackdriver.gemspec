
require File.expand_path("../lib/stackdriver/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "stackdriver"
  gem.version       = Stackdriver::VERSION

  gem.authors       = ["Heng Xiong"]
  gem.email         = ["hxiong388@gmail.com"]
  gem.description   = "stackdriver is the official library for Google Stackdriver APIs."
  gem.summary       = "API Client library for Google Stackdriver"
  gem.homepage      = "https://github.com/googleapis/google-cloud-ruby/tree/master/stackdriver"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files -- lib/*`.split("\n") +
                      ["OVERVIEW.md", "INSTRUMENTATION_CONFIGURATION.md", "CONTRIBUTING.md", "CHANGELOG.md", "CODE_OF_CONDUCT.md", "LICENSE", ".yardopts"]
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.2.0"

  gem.add_runtime_dependency "google-cloud-debugger", "~> 0.32"
  gem.add_runtime_dependency "google-cloud-error_reporting", "~> 0.30"
  gem.add_runtime_dependency "google-cloud-logging", "~> 1.5"
  gem.add_runtime_dependency "google-cloud-trace", "~> 0.33"

  gem.add_development_dependency "minitest", "~> 5.10"
  gem.add_development_dependency "minitest-autotest", "~> 1.0"
  gem.add_development_dependency "minitest-focus", "~> 1.1"
  gem.add_development_dependency "minitest-rg", "~> 5.2"
  gem.add_development_dependency "autotest-suffix", "~> 1.1"
  gem.add_development_dependency "redcarpet", "~> 3.0"
  gem.add_development_dependency "rubocop", "~> 0.64.0"
  gem.add_development_dependency "simplecov", "~> 0.9"
  gem.add_development_dependency "yard", "~> 0.9"
  gem.add_development_dependency "yard-doctest", "~> 0.1.6"
  gem.add_development_dependency "railties", "~> 4.0"
end
