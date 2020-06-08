# frozen_string_literal: true

module Sleet
  class Repo
    REMOTE_BRANCH_REGEX = %r{^([^\/.]+)\/(.+)}.freeze
    CURRENT_BRANCH_REGEX = %r{^refs\/heads\/}.freeze
    GITHUB_MATCH_REGEX = %r{github.com[:\/](.+)\/(.+)\.git}.freeze

    def self.from_config(config)
      new(
        repo: Rugged::Repository.new(config.source_dir),
        circle_ci_token: config.circle_ci_token,
        branch: config.branch,
      )
    end

    def initialize(repo:, circle_ci_token:, branch:)
      @repo = repo
      @circle_ci_token = circle_ci_token
      @branch = build_branch(branch) if branch
    end

    def validate!
      must_be_on_branch!
      must_have_an_upstream_branch!
      upstream_remote_must_be_github!
    end

    def branch
      @branch ||= build_branch(remote_branch)
    end

    def build_for(build_num)
      Sleet::Build.new(
        circle_ci_token: circle_ci_token,
        github_user: github_user,
        github_repo: github_repo,
        build_num: build_num
      )
    end

    private

    attr_reader :repo, :circle_ci_token

    def build_branch(branch)
      Sleet::Branch.new(
        circle_ci_token: circle_ci_token,
        github_user: github_user,
        github_repo: github_repo,
        branch: branch
      )
    end

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
      @github_match ||= GITHUB_MATCH_REGEX.match(current_branch.remote.url)
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
