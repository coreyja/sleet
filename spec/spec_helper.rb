# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sleet'

require 'English'
require 'fileutils'
require 'tmpdir'

require 'webmock/rspec'
require 'pry'

WebMock.disable_net_connect!

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |c|
  c.expect_with :rspec do |config|
    config.include_chain_clauses_in_custom_matcher_descriptions = true
  end
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

  c.after :each do
    Sleet::CircleCi.instance.reset!
  end
end
