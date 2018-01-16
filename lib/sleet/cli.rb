# frozen_string_literal: true

module Sleet
  class Cli < Thor
    default_task :fetch

    desc 'fetch', 'Fetch and Aggregate RSpec Persistance Files from CircleCI'
    long_desc <<~LONGDESC
      `sleet fetch` will find build(s) in CircleCI for the current branch, and
      download the chosen Rspec Persistance Files. Since there will be 1 per container,
      and builds may have more than 1 container `sleet` will combine all the indivudual
      persistance files.
    LONGDESC
    option :source_dir, type: :string, aliases: [:s], desc: <<~DESC
      This is the directory of the source git repo. If a source_dir is NOT given we look up from the current directory for the nearest git repo.
    DESC
    option :input_file, type: :string, aliases: [:i], desc: <<~DESC
      This is the name of the Rspec Circle Persistance File in CircleCI. The default is .rspec_example_statuses. This will match if the full path on CircleCI ends in the given name.
    DESC
    option :output_file, type: :string, aliases: [:o], desc: <<~DESC
      This is the name for the output file, on your local system. It is relative to the source_dir. Will be IGNORED if workflows is provided.
    DESC
    option :workflows, type: :hash, aliases: [:w], desc: <<~DESC
      To use Sleet with CircleCI Workflows you need to tell Sleet which build(s) to look in, and where each output should be saved. The input is a hash, where the key is the build name and the value is the output_file for that build. Sleet supports saving the artifacts to multiple builds, meaning it can support a mono-repo setup.
    DESC
    def fetch
      if options[:workflows]
        workflow_fetch
      else
        single_fetch
      end
    end

    private

    def single_fetch
      Sleet::Fetcher.new(
        base_fetcher_params.merge(
          output_filename: options.fetch(:output_file, '.rspec_example_statuses')
        )
      ).do!
    rescue Sleet::Error => e
      error(e.message)
      exit 1
    end

    def workflow_fetch
      failed = false
      options[:workflows].each do |job_name, output_filename|
        begin
          Sleet::Fetcher.new(
            base_fetcher_params.merge(
              output_filename: output_filename,
              job_name: job_name
            )
          ).do!
        rescue Sleet::Error => e
          failed = true
          error(e.message)
        end
      end
      exit 1 if failed
    end

    def base_fetcher_params
      {
        source_dir: options.fetch(:source_dir, default_dir),
        input_filename: options.fetch(:input_file, '.rspec_example_statuses')
      }
    end

    def error(message)
      puts "ERROR: #{message}".red
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
