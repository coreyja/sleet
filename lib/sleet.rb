# frozen_string_literal: true

require 'colorize'
require 'faraday'
require 'faraday_middleware'
require 'forwardable'
require 'json'
require 'rspec'
require 'rugged'
require 'terminal-table'
require 'thor'
require 'yaml'

# This is to load the classes that are defined in the same file as this one
# We are most definitely relying on Private API here
begin
  RSpec::Core::ExampleStatusPersister
end

require 'sleet/artifact_downloader'
require 'sleet/branch'
require 'sleet/build'
require 'sleet/build_selector'
require 'sleet/circle_ci'
require 'sleet/config'
require 'sleet/error'
require 'sleet/fetch_command'
require 'sleet/job_fetcher'
require 'sleet/local_repo'
require 'sleet/repo'
require 'sleet/rspec_file_merger'
require 'sleet/version'

require 'sleet/cli'

module Sleet
end
