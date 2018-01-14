require 'yaml'

class CRSPFA::Cli < Thor
  default_task :fetch

  desc 'Fetch Rspec Status File from CircleCI', 'fetch'
  option :source, type: :string, aliases: [:s]
  def fetch
    source_dir = options.fetch(:source, Dir.pwd)
    foo = CRSPFA::CurrentBranchGithub.from_dir(source_dir)

    branch = CRSPFA::CircleCiBranch.new(github_user: foo.github_user, github_repo: foo.github_repo, branch: foo.remote_branch)

    build = branch.builds_with_artificats.first

    build = CRSPFA::CircleCiBuild.new(github_user: foo.github_user, github_repo: foo.github_repo, build_num: build['build_num'])

    files = CRSPFA::ArtifactDownloader.new(build.artifacts).files
    puts CRSPFA::RspecFileMerger.new(files).output
  end

  private

  def options
    original_options = super
    defaults = CRSPFA::OptionDefaults.new(Dir.pwd).defaults
    Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
  end
end
