# frozen_string_literal: true

module Sleet
  class Repo
    REMOTE_BRANCH_REGEX = %r{^([^\/.]+)\/(.+)}
    CURRENT_BRANCH_REGEX = %r{^refs\/heads\/}
    GITHUB_MATCH_REGEX = %r{github.com[:\/](.+)\/(.+)\.git}

    def self.from_dir(dir)
      new(repo: Rugged::Repository.new(dir))
    end

    def initialize(repo:)
      @repo = repo
    end

    def validate!
      must_be_on_branch!
      must_have_an_upstream_branch!
      upstream_remote_must_be_github!
    end

    def circle_ci_branch
      @_circle_ci_branch ||= Sleet::CircleCiBranch.new(
        github_user: github_user,
        github_repo: github_repo,
        branch: remote_branch
      )
    end

    def circle_ci_build_for(build_num)
      Sleet::CircleCiBuild.new(
        github_user: github_user,
        github_repo: github_repo,
        build_num: build_num
      )
    end

    private

    attr_reader :repo

    def remote_branch
      current_branch.upstream.name.match(REMOTE_BRANCH_REGEX)[2]
    end

    def github_user
      github_match[1]
    end

    def github_repo
      github_match[2]
    end

    def current_branch_name
      repo.head.name.sub(CURRENT_BRANCH_REGEX, '')
    end

    def current_branch
      repo.branches[current_branch_name]
    end

    def github_match
      @_github_match ||= GITHUB_MATCH_REGEX.match(current_branch.remote.url)
    end

    def must_be_on_branch!
      !current_branch.nil? ||
        raise(Error, 'Not on a branch')
    end

    def must_have_an_upstream_branch!
      !current_branch.remote.nil? ||
        raise(Error, "No upstream branch set for the current branch of #{repo.current_branch_name}")
    end

    def upstream_remote_must_be_github!
      !github_match.nil? ||
        raise(Error, 'Upstream remote is not GitHub')
    end
  end
end
