# frozen_string_literal: true

module Sleet
  class CircleCiBuild
    attr_reader :build_num

    def initialize(github_user:, github_repo:, build_num:)
      @github_user = github_user
      @github_repo = github_repo
      @build_num = build_num
    end

    def artifacts
      @_artifacts ||= JSON.parse(Sleet::CircleCi.get(url).body)
    end

    private

    attr_reader :github_user, :github_repo

    def url
      "https://circleci.com/api/v1.1/project/github/#{github_user}/#{github_repo}/#{build_num}/artifacts"
    end
  end
end
