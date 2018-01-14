# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sleet'

RSpec.configure do |c|
  c.example_status_persistence_file_path = 'spec/.rspec_example_statuses'
end
