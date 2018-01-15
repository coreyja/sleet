# frozen_string_literal: true

module Sleet
  class Cli < Thor
    default_task :fetch

    desc 'Fetch Rspec Status File from CircleCI', 'fetch'
    option :source_dir, type: :string, aliases: [:s]
    option :input_file, type: :string, aliases: [:i]
    option :output_file, type: :string, aliases: [:o]
    def fetch
      fetcher.validate!
      fetcher.create_output_file!
    end

    private

    def fetcher
      @_fetcher ||= Sleet::Fetcher.new(fetcher_params)
    end

    def fetcher_params
      {
        source_dir: options.fetch(:source_dir, default_dir),
        input_filename: options.fetch(:input_file, '.rspec_example_statuses'),
        output_filename: options.fetch(:output_file, '.rspec_example_statuses'),
        error_proc: ->(x) { error(x) }
      }
    end

    def error(message)
      puts "ERROR: #{message}".red
      exit 1
    end

    def default_dir
      Rugged::Repository.discover(Dir.pwd).path + '..'
    end

    def options
      original_options = super
      defaults = Sleet::OptionDefaults.new(Dir.pwd).defaults
      Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
    end
  end
end
