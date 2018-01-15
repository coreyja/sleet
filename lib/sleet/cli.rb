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

      current_branch = Sleet::Repo.from_dir(source_dir)

      error 'Not on a branch' unless current_branch.on_branch?
      error "No upstream branch set for the current branch of #{current_branch.current_branch_name}" unless current_branch.has_remote?
      error 'Upstream remote is not GitHub' unless current_branch.is_github?

      branch = Sleet::CircleCiBranch.new(
        github_user: current_branch.github_user,
        github_repo: current_branch.github_repo,
        branch: current_branch.remote_branch
      )

      build = branch.builds_with_artificats.first

      error 'No builds with artifcats found' if build.nil?

      build = Sleet::CircleCiBuild.new(
        github_user: current_branch.github_user,
        github_repo: current_branch.github_repo,
        build_num: build['build_num']
      )

      error "No Rspec example file found in the latest build (##{build.build_num}) with artifacts" unless build.artifacts.any?

      files = Sleet::ArtifactDownloader.new(file_name: file_name, artifacts: build.artifacts).files
      Dir.chdir(source_dir) do
        File.write(output_file, Sleet::RspecFileMerger.new(files).output)
      end
    end

    private

    def error(message)
      puts "ERROR: #{message}"
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
