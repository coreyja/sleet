# frozen_string_literal: true

module Sleet
  class Repo
    REMOTE_BRANCH_REGEX = %r{^([^\/.]+)\/(.+)}.freeze
    CURRENT_BRANCH_REGEX = %r{^refs\/heads\/}.freeze
    GITHUB_MATCH_REGEX = %r{github.com[:\/](.+)\/(.+)\.git}.freeze

    attr_reader :branch

    def self.from_config(config)
      if config.username && config.project && config.branch
        new(
          circle_ci_token: config.circle_ci_token,
          username: config.username,
          project: config.project,
          branch: config.branch
        )
      else
        repo = Rugged::Repository.new(config.source_dir)
        current_branch_name = repo.head.name.sub(CURRENT_BRANCH_REGEX, '')
        current_branch = repo.branches[current_branch_name]

        !current_branch.nil? ||
          raise(Error, 'Not on a branch')

        !current_branch.remote.nil? ||
          raise(Error, "No upstream branch set for the current branch of #{repo.current_branch_name}")

        github_match = GITHUB_MATCH_REGEX.match(current_branch.remote.url)

        !github_match.nil? ||
          raise(Error, 'Upstream remote is not GitHub')

        remote_branch = current_branch.upstream.name.match(REMOTE_BRANCH_REGEX)[2]
        new(
          circle_ci_token: config.circle_ci_token,
          username: github_match[1],
          project: github_match[2],
          branch: remote_branch
        )
      end
    end

    def initialize(circle_ci_token:, username:, project:, branch:)
      @circle_ci_token = circle_ci_token
      @github_user = username
      @github_repo = project
      @branch = build_branch(branch)
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

    attr_reader :circle_ci_token, :github_user, :github_repo

    def build_branch(branch)
      Sleet::Branch.new(
        circle_ci_token: circle_ci_token,
        github_user: github_user,
        github_repo: github_repo,
        branch: branch
      )
    end
  end
end
