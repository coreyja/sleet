# frozen_string_literal: true

module Sleet
  class LocalRepo
    REMOTE_BRANCH_REGEX = %r{^([^\/.]+)\/(.+)}.freeze
    CURRENT_BRANCH_REGEX = %r{^refs\/heads\/}.freeze
    GITHUB_MATCH_REGEX = %r{github.com[:\/](.+)\/(.+)\.git}.freeze

    def initialize(source_dir:)
      @source_dir = source_dir
    end

    def username
      validate!

      github_match[1]
    end

    def project
      validate!

      github_match[2]
    end

    def branch_name
      validate!

      current_branch.upstream.name.match(REMOTE_BRANCH_REGEX)[2]
    end

    private

    attr_reader :source_dir

    def current_branch_name
      @current_branch_name ||= repo.head.name.sub(CURRENT_BRANCH_REGEX, '')
    end

    def current_branch
      @current_branch ||= repo.branches[current_branch_name]
    end

    def github_match
      @github_match ||= GITHUB_MATCH_REGEX.match(current_branch.remote.url)
    end

    def repo
      @repo ||= Rugged::Repository.new(source_dir)
    end

    def validate!
      return if @validated

      must_be_on_branch!
      must_have_an_upstream_branch!
      upstream_remote_must_be_github!
      @validated = true
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
