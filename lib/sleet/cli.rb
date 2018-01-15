# frozen_string_literal: true

module Sleet
  class Cli < Thor
    default_task :fetch

    desc 'Fetch Rspec Status File from CircleCI', 'fetch'
    option :source_dir, type: :string, aliases: [:s]
    option :input_file, type: :string, aliases: [:i]
    option :output_file, type: :string, aliases: [:o]
    def fetch
      Sleet::Fetcher.new(
        source_dir: options.fetch(:source_dir, default_dir),
        input_filename: options.fetch(:input_file, '.rspec_example_statuses'),
        output_filename: options.fetch(:output_file, '.rspec_example_statuses'),
        error_proc: ->(x) { error(x) }
      ).do!
    end

    desc 'Monorepo: Using workflows in CircleCI fetch for multiple seperate subdirs', 'monorepo'
    option :source_dir, type: :string, aliases: [:s]
    option :input_file, type: :string, aliases: [:i]
    option :workflows, type: :hash, aliases: [:w], required: true
    def monorepo
      options[:workflows].each do |job_name, output_filename|
        Sleet::Fetcher.new(
          source_dir: options.fetch(:source_dir, default_dir),
          input_filename: options.fetch(:input_file, '.rspec_example_statuses'),
          output_filename: output_filename,
          job_name: job_name,
          error_proc: ->(x) { error(x) }
        ).do!
      end
    end

    private

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
