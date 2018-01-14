# frozen_string_literal: true

module Sleet
  class Cli < Thor
    default_task :fetch

    desc 'Fetch Rspec Status File from CircleCI', 'fetch'
    option :source_dir, type: :string, aliases: [:s]
    option :input_file, type: :string, aliases: [:i]
    option :output_file, type: :string, aliases: [:o]
    def fetch
      source_dir = options.fetch(:source_dir, default_dir)
      file_name = options.fetch(:input_file, '.rspec_example_statuses')
      output_file = options.fetch(:output_file, '.rspec_example_statuses')

      current_branch = Sleet::CurrentBranchGithub.from_dir(source_dir)

      branch = Sleet::CircleCiBranch.new(
        github_user: current_branch.github_user,
        github_repo: current_branch.github_repo,
        branch: current_branch.remote_branch
      )

      build = branch.builds_with_artificats.first

      build = Sleet::CircleCiBuild.new(
        github_user: current_branch.github_user,
        github_repo: current_branch.github_repo,
        build_num: build['build_num']
      )

      files = Sleet::ArtifactDownloader.new(file_name: file_name, artifacts: build.artifacts).files
      Dir.chdir(source_dir) do
        File.write(output_file, Sleet::RspecFileMerger.new(files).output)
      end
    end

    private

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
