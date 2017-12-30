module CRSPFA
  class CurrentBranchGithub
    def self.from_dir(dir)
      new(repo: Rugged::Repository.new(dir))
    end

    def initialize(repo:)
      @repo = repo
      raise 'NOT GITHUB' unless github_match
    end

    def remote_branch
      current_branch.upstream.name.match(/^([^\/.]+)\/(.+)/)[2]
    end

    def github_user
      github_match[1]
    end

    def github_repo
      github_match[2]
    end

    private

    attr_reader :repo

    def current_branch
      repo.branches[current_branch_name]
    end

    def current_branch_name
      repo.head.name.sub(/^refs\/heads\//, '')
    end

    def github_match
      @_github_match ||= /github.com[:\/](.+)\/(.+)\.git/.match(current_branch.remote.url)
    end
  end
end
