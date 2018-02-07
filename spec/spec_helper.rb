# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sleet'

require 'English'
require 'open3'
require 'tmpdir'

require 'webmock/rspec'
require 'pry'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |c|
  c.example_status_persistence_file_path = 'spec/.rspec_example_statuses'

  c.before :each, type: :cli do
    extend CliHelper
  end

  c.around :each, type: :cli do |example|
    Dir.mktmpdir do |spec_dir|
      Dir.chdir(spec_dir) do
        example.run
      end
    end
  end
end
