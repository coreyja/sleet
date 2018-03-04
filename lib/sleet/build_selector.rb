# frozen_string_literal: true

module Sleet
  class BuildSelector
    def initialize(repo:, job_name:)
      @repo = repo
      @job_name = job_name
    end

    def build
      @_build ||= repo.circle_ci_build_for(chosen_build_num)
    end

    def validate!
      must_find_a_build_with_artifacts!
      chosen_build_must_have_input_file!
    end

    private

    attr_reader :repo, :job_name

    def circle_ci_branch
      repo.circle_ci_branch
    end

    def chosen_build_num
      chosen_build_json['build_num']
    end

    def chosen_build_json
      circle_ci_branch.builds_with_artificats.find do |b|
        b.fetch('workflows', nil)&.fetch('job_name', nil) == job_name
      end
    end

    def must_find_a_build_with_artifacts!
      !chosen_build_json.nil? ||
        raise(Error, "No builds with artifcats found#{" for job name [#{job_name}]" if job_name}")
    end

    def chosen_build_must_have_input_file!
      build.artifacts.any? ||
        raise(Error, "No Rspec example file found in the latest build (##{chosen_build_num}) with artifacts")
    end
  end
end
