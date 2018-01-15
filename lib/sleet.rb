# frozen_string_literal: true

require 'colorize'
require 'faraday'
require 'json'
require 'rspec'
require 'rugged'
require 'thor'
require 'yaml'

# This is to load the classes that are defined in the same file as this one
begin
  RSpec::Core::ExampleStatusPersister
end

require 'sleet/artifact_downloader'
require 'sleet/circle_ci'
require 'sleet/circle_ci_branch'
require 'sleet/circle_ci_build'
require 'sleet/fetcher'
require 'sleet/option_defaults'
require 'sleet/repo'
require 'sleet/rspec_file_merger'
require 'sleet/version'

require 'sleet/cli'

module Sleet
end
