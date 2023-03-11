# frozen_string_literal: true

module Sleet
  class Branch
    def initialize(circle_ci_token:, github_user:, github_repo:, branch:)
      @circle_ci_token = circle_ci_token
      @github_user = github_user
      @github_repo = github_repo
      @branch = CGI.escape(branch)
    end

    def builds
      @builds ||= JSON.parse(Sleet::CircleCi.get(url, circle_ci_token).body)
    end

    private

    attr_reader :github_user, :github_repo, :branch, :circle_ci_token

    def url
      "https://circleci.com/api/v1.1/project/github/#{github_user}/#{github_repo}/tree/#{branch}" \
        '?filter=completed&limit=100'
    end
  end
end
