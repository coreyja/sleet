require 'thor'
require 'json'
require 'rugged'
require 'faraday'
require 'rspec'
begin
  RSpec::Core::ExampleStatusPersister
end

require 'sleet/artifact_downloader'
require 'sleet/circle_ci'
require 'sleet/circle_ci_branch'
require 'sleet/circle_ci_build'
require 'sleet/current_branch_github'
require 'sleet/option_defaults'
require 'sleet/rspec_file_merger'
require 'sleet/version'

require 'sleet/cli'

module Sleet
end
