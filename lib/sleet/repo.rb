# frozen_string_literal: true

module Sleet
  class Repo

    def self.from_config(config)
      if config.username && config.project && config.branch
        new(
          circle_ci_token: config.circle_ci_token,
          username: config.username,
          project: config.project,
          branch_name: config.branch
        )
      else
        local_repo = Sleet::LocalRepo.new(source_dir: config.source_dir)
        local_repo.validate!

        new(
          circle_ci_token: config.circle_ci_token,
          username: local_repo.username,
          project: local_repo.project,
          branch_name: local_repo.branch_name
        )
      end
    end

    def initialize(circle_ci_token:, username:, project:, branch_name:)
      @circle_ci_token = circle_ci_token
      @github_user = username
      @github_repo = project
      @branch_name = branch_name
    end

    def build_for(build_num)
      Sleet::Build.new(
        circle_ci_token: circle_ci_token,
        github_user: github_user,
        github_repo: github_repo,
        build_num: build_num
      )
    end

    def branch
      @branch ||= Sleet::Branch.new(
        circle_ci_token: circle_ci_token,
        github_user: github_user,
        github_repo: github_repo,
        branch: branch_name
      )
    end

    private

    attr_reader :circle_ci_token, :github_user, :github_repo, :branch_name
  end
end
