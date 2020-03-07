# frozen_string_literal: true

module Sleet
  class BuildSelector
    def initialize(repo:, job_name:)
      @repo = repo
      @job_name = job_name
    end

    def build
      @build ||= repo.build_for(chosen_build_num)
    end

    def validate!
      must_find_a_build_with_artifacts!
      chosen_build_must_have_input_file!
    end

    private

    attr_reader :repo, :job_name

    def branch
      repo.branch
    end

    def chosen_build_num
      chosen_build_json['build_num']
    end

    def chosen_build_json
      branch.builds_with_artifacts.find do |b|
        b.fetch('workflows', nil)&.fetch('job_name', nil) == job_name
      end
    end

    def must_find_a_build_with_artifacts!
      !chosen_build_json.nil? ||
        raise(Error, "No builds with artifacts found#{" for job name [#{job_name}]" if job_name}")
    end

    def chosen_build_must_have_input_file!
      build.artifacts.any? ||
        raise(Error, "No Rspec example file found in the latest build (##{chosen_build_num}) with artifacts")
    end
  end
end
