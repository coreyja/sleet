# frozen_string_literal: true

module Sleet
  class Fetcher
    def initialize(source_dir:, input_filename:, output_filename:, error_proc:, job_name: nil)
      @source_dir = source_dir
      @input_filename = input_filename
      @output_filename = output_filename
      @error_proc = error_proc
      @job_name = job_name
    end

    def do!
      validate!
      create_output_file!
    end

    def validate!
      must_be_on_branch!
      must_have_an_upstream_branch!
      upstream_remote_must_be_github!
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

    attr_reader :source_dir, :input_filename, :output_filename, :error_proc, :job_name

    def error(msg)
      error_proc.call(msg)
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
        github_user: repo.github_user,
        github_repo: repo.github_repo,
        build_num: chosen_build_json['build_num']
      )
    end

    def repo
      @_repo ||= Sleet::Repo.from_dir(source_dir)
    end

    def chosen_build_json
      if job_name
        circle_ci_branch.builds_with_artificats.find { |b| b.fetch('workflows', {})&.fetch('job_name', {}) == job_name }
      else
        circle_ci_branch.builds_with_artificats.first
      end
    end

    def circle_ci_branch
      @_circle_ci_branch ||= Sleet::CircleCiBranch.new(
        github_user: repo.github_user,
        github_repo: repo.github_repo,
        branch: repo.remote_branch
      )
    end

    def must_be_on_branch!
      repo.on_branch? ||
        error('Not on a branch')
    end

    def must_have_an_upstream_branch!
      repo.remote? ||
        error("No upstream branch set for the current branch of #{repo.current_branch_name}")
    end

    def upstream_remote_must_be_github!
      repo.github? ||
        error('Upstream remote is not GitHub')
    end

    def must_find_a_build_with_artifacts!
      !chosen_build_json.nil? ||
        error("No builds with artifcats found #{"for job name [#{job_name}]" if job_name}")
    end

    def chosen_build_must_have_input_file!
      circle_ci_build.artifacts.any? ||
        error("No Rspec example file found in the latest build (##{circle_ci_build.build_num}) with artifacts")
    end
  end
end
