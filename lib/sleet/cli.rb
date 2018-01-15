# frozen_string_literal: true

module Sleet
  class Cli < Thor
    default_task :fetch

    desc 'Fetch Rspec Status File from CircleCI', 'fetch'
    option :source_dir, type: :string, aliases: [:s]
    option :input_file, type: :string, aliases: [:i]
    option :output_file, type: :string, aliases: [:o]
    option :workflows, type: :hash, aliases: [:w]
    def fetch
      if options[:worflows]
        workflow_fetch
      else
        single_fetch
      end
    end

    private

    def single_fetch
      Sleet::Fetcher.new(
        source_dir: options.fetch(:source_dir, default_dir),
        input_filename: options.fetch(:input_file, '.rspec_example_statuses'),
        output_filename: options.fetch(:output_file, '.rspec_example_statuses'),
        error_proc: ->(x) { error!(x) }
      ).do!
    rescue Sleet::Error => e
      error!(e.message)
    end

    def workflow_fetch
      failed = false
      options[:workflows].each do |job_name, output_filename|
        begin
          Sleet::Fetcher.new(
            source_dir: options.fetch(:source_dir, default_dir),
            input_filename: options.fetch(:input_file, '.rspec_example_statuses'),
            output_filename: output_filename,
            job_name: job_name
          ).do!
        rescue Sleet::Error => e
          failed = true
          error(e.message)
        end
      end
      exit 1 if failed
    end

    def error(message)
      puts "ERROR: #{message}".red
    end

    def error!(message)
      error(message)
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
