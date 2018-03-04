# frozen_string_literal: true

require 'colorize'
require 'faraday'
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
require 'sleet/circle_ci'
require 'sleet/circle_ci_branch'
require 'sleet/circle_ci_build'
require 'sleet/config'
require 'sleet/error'
require 'sleet/fetcher'
require 'sleet/repo'
require 'sleet/rspec_file_merger'
require 'sleet/version'

require 'sleet/cli'

module Sleet
end
