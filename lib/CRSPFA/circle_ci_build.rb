class CRSPFA::CircleCiBuild
  def initialize(github_user:, github_repo:, build_num:)
    @github_user = github_user
    @github_repo = github_repo
    @build_num = build_num
  end

  def artifacts
    @_artifacts ||= JSON.parse(CRSPFA::CircleCi.get(url).body)
  end

  private

  attr_reader :github_user, :github_repo, :build_num

  def url
    "https://circleci.com/api/v1.1/project/github/#{github_user}/#{github_repo}/#{build_num}/artifacts"
  end
end
