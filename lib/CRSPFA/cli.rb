class CRSPFA::Cli < Thor
  desc 'do It', 'do'
  def do
    foo = CRSPFA::CurrentBranchGithub.from_dir("#{Dir.home}/Projects/hash_attribute_assignment")

    url="https://circleci.com/api/v1.1/project/github/#{foo.github_user}/#{foo.github_repo}/tree/#{foo.remote_branch}"
    builds = JSON.parse(CRSPFA::CircleCi.get(url).body)
    builds_with_artificats = builds.select { |b| b['has_artifacts'] }

    build = builds_with_artificats.first
    url="https://circleci.com/api/v1.1/project/github/#{foo.github_user}/#{foo.github_repo}/#{build['build_num']}/artifacts"
    artifacts = JSON.parse(CRSPFA::CircleCi.get(url).body)

    files = CRSPFA::ArtifactDownloader.new(artifacts).files

    p CRSPFA::RspecFileMerger.new(files).output
  end
end
