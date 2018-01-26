# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sleet'
require 'English'

require 'webmock/rspec'
require 'aruba/rspec'
require 'aruba/api'

RSpec.configure do |c|
  c.example_status_persistence_file_path = 'spec/.rspec_example_statuses'

  c.include ArubaDoubles
  c.include Aruba::Api

  c.before :each, type: :aruba do
    Aruba::RSpec.setup
  end

  c.after :each, type: :aruba do
    Aruba::RSpec.teardown
  end

  c.around :each, type: :aruba do |example|
    Dir.chdir('tmp/aruba') do
      example.run
    end
  end
end
