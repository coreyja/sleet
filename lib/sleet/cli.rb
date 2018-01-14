require 'yaml'

module Sleet
  class Cli < Thor
    default_task :fetch

    desc 'Fetch Rspec Status File from CircleCI', 'fetch'
    option :source, type: :string, aliases: [:s]
    def fetch
      source_dir = options.fetch(:source, Dir.pwd)
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

      files = Sleet::ArtifactDownloader.new(build.artifacts).files
      puts Sleet::RspecFileMerger.new(files).output
    end

    private

    def options
      original_options = super
      defaults = Sleet::OptionDefaults.new(Dir.pwd).defaults
      Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
    end
  end
end
