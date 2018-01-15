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

    def has_remote?
      !current_branch.remote.nil?
    end

    def is_github?
      !github_match.nil?
    end

    def on_branch?
      !current_branch.nil?
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

    private

    attr_reader :repo

    def current_branch
      repo.branches[current_branch_name]
    end

    def github_match
      @_github_match ||= GITHUB_MATCH_REGEX.match(current_branch.remote.url)
    end
  end
end
