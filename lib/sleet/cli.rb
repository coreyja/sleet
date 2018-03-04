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
    option :print_config, type: :boolean, default: false
    def fetch
      if options[:print_config]
        _config.print!
        exit
      end
      error_messages = []
      job_name_to_output_files.each do |job_name, output_filename|
        begin
          Sleet::Fetcher.new(
            source_dir: options.fetch(:source_dir),
            input_filename: options.fetch(:input_file),
            output_filename: output_filename,
            job_name: job_name
          ).do!
        rescue Sleet::Error => e
          error_messages << e.message
        end
      end
      raise Thor::Error, error_messages.join("\n") unless error_messages.empty?
    end

    desc 'version', 'Display the version'
    def version
      puts "Sleet v#{Sleet::VERSION}"
    end

    desc 'config', 'Print the config'
    def config
      _config.print!
    end

    private

    def job_name_to_output_files
      options[:workflows] || { nil => options.fetch(:output_file) }
    end

    no_commands { alias_method :thor_options, :options }
    def options
      _config.options_hash
    end

    def _config
      @_config ||= Sleet::Config.new(cli_hash: thor_options, dir: Dir.pwd)
    end
  end
end
