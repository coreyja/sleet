require 'yaml'

class CRSPFA::Cli < Thor
  default_task :fetch

  desc 'do It', 'fetch'
  option :source, type: :string, aliases: [:s]
  def fetch
    source_dir = options.fetch(:source, Dir.pwd)
    foo = CRSPFA::CurrentBranchGithub.from_dir(source_dir)

    url="https://circleci.com/api/v1.1/project/github/#{foo.github_user}/#{foo.github_repo}/tree/#{foo.remote_branch}"
    builds = JSON.parse(CRSPFA::CircleCi.get(url).body)
    builds_with_artificats = builds.select { |b| b['has_artifacts'] }

    build = builds_with_artificats.first
    url="https://circleci.com/api/v1.1/project/github/#{foo.github_user}/#{foo.github_repo}/#{build['build_num']}/artifacts"
    artifacts = JSON.parse(CRSPFA::CircleCi.get(url).body)

    files = CRSPFA::ArtifactDownloader.new(artifacts).files

    puts CRSPFA::RspecFileMerger.new(files).output
  end

  private

  def options
    original_options = super
    defaults = CRSPFA::OptionDefaults.new(Dir.pwd).defaults
    Thor::CoreExt::HashWithIndifferentAccess.new(defaults.merge(original_options))
  end
end
