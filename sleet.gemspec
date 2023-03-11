# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sleet/version'

Gem::Specification.new do |spec|
  spec.name          = 'sleet'
  spec.version       = Sleet::VERSION
  spec.authors       = ['Corey Alexander']
  spec.email         = ['coreyja@gmail.com']

  spec.summary       = 'CircleCI RSpec Status Persistance File Aggregator'
  spec.description   = <<~DOC
    Sleet provides an easy way to grab the most recent Rspec persistance files from CircleCI.
    It also aggregates the artifacts from CircleCI, since you will have 1 per build container.
  DOC
  spec.homepage      = 'https://github.com/coreyja/sleet'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'colorize', '~> 0.8.1'
  spec.add_dependency 'faraday', '>= 0.13.1', '< 1.1.0'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'rugged', '>= 0.27', '< 1.6'
  spec.add_dependency 'terminal-table', '~> 1.8'
  spec.add_dependency 'thor', '>= 0.20', '< 1.1'

  spec.add_development_dependency 'gem-release', '= 2.1.1'
  spec.add_development_dependency 'github_changelog_generator', '~> 1.14'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop-coreyja', '0.4.0'
  spec.add_development_dependency 'webmock', '~> 3.8.0'
end
