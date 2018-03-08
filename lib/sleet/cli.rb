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
    option :print_config, type: :boolean
    def fetch
      sleet_config = Sleet::Config.new(cli_hash: options, dir: Dir.pwd)
      if options[:print_config]
        sleet_config.print!
        exit
      end
      raise Sleet::Error, 'circle_ci_token required and not provided' unless sleet_config.circle_ci_token
      Sleet::FetchCommand.new(sleet_config).do!
    end

    desc 'version', 'Display the version'
    option :bare, type: :boolean, default: false
    def version
      if options[:bare]
        puts Sleet::VERSION
      else
        puts "Sleet v#{Sleet::VERSION}"
      end
    end

    desc 'config', 'Print the config'
    option :show_sensitive, type: :boolean
    def config
      Sleet::Config.new(cli_hash: options, dir: Dir.pwd).print!
    end
  end
end
