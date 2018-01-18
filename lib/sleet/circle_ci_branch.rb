# frozen_string_literal: true

module Sleet
  class CircleCiBranch
    def initialize(github_user:, github_repo:, branch:)
      @github_user = github_user
      @github_repo = github_repo
      @branch = branch
    end

    def builds
      @_builds ||= JSON.parse(Sleet::CircleCi.get(url).body)
    end

    def builds_with_artificats
      builds.select { |b| b['has_artifacts'] }
    end

    private

    attr_reader :github_user, :github_repo, :branch

    def url
      "https://circleci.com/api/v1.1/project/github/#{github_user}/#{github_repo}/tree/#{branch}?filter=completed"
    end
  end
end
