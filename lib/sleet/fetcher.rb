# frozen_string_literal: true

module Sleet
  class Fetcher
    class Error < ::Sleet::Error; end

    def initialize(source_dir:, circle_ci_branch:, input_filename:, output_filename:, github_user:, github_repo:, job_name: nil) # rubocop:disable Metrics/LineLength
      @source_dir = source_dir
      @circle_ci_branch = circle_ci_branch
      @input_filename = input_filename
      @output_filename = output_filename
      @job_name = job_name
      @github_user = github_user
      @github_repo = github_repo
    end

    def do!
      validate!
      create_output_file!
    end

    def validate!
      must_find_a_build_with_artifacts!
      chosen_build_must_have_input_file!
      true
    end

    def create_output_file!
      Dir.chdir(source_dir) do
        File.write(output_filename, combined_file)
      end
      puts "Created file (#{output_filename}) from build (##{circle_ci_build.build_num})".green
    end

    private

    attr_reader :input_filename, :output_filename, :job_name, :circle_ci_branch, :github_user, :github_repo, :source_dir

    def error(msg)
      raise Error, "ERROR: #{msg}".red
    end

    def combined_file
      @_combined_file ||= Sleet::RspecFileMerger.new(build_persistance_artifacts).output
    end

    def build_persistance_artifacts
      @_build_persistance_artifacts ||= Sleet::ArtifactDownloader.new(
        file_name: input_filename,
        artifacts: circle_ci_build.artifacts
      ).files
    end

    def circle_ci_build
      @_circle_ci_build ||= Sleet::CircleCiBuild.new(
        github_user: github_user,
        github_repo: github_repo,
        build_num: chosen_build_json['build_num']
      )
    end

    def chosen_build_json
      if job_name
        circle_ci_branch.builds_with_artificats.find { |b| b.fetch('workflows', {})&.fetch('job_name', {}) == job_name }
      else
        circle_ci_branch.builds_with_artificats.first
      end
    end

    def must_find_a_build_with_artifacts!
      !chosen_build_json.nil? ||
        error("No builds with artifcats found#{" for job name [#{job_name}]" if job_name}")
    end

    def chosen_build_must_have_input_file!
      circle_ci_build.artifacts.any? ||
        error("No Rspec example file found in the latest build (##{circle_ci_build.build_num}) with artifacts")
    end
  end
end
