require 'thor'
require 'json'
require 'rugged'
require 'faraday'
require 'rspec'; RSpec::Core::ExampleStatusPersister

require "CRSPFA/circle_ci"
require "CRSPFA/current_branch_github"
require "CRSPFA/rspec_file_merger"
require "CRSPFA/version"

require "CRSPFA/cli"

module CRSPFA
end
