# frozen_string_literal: true

module Sleet
  class Fetcher
    def initialize(source_dir:, input_filename:, output_filename:, job_name:, repo:)
      @source_dir = source_dir
      @input_filename = input_filename
      @output_filename = output_filename
      @job_name = job_name
      @repo = repo
    end

    def do!
      validate!
      create_output_file!
    end

    private

    attr_reader :input_filename, :output_filename, :job_name, :source_dir, :repo

    def validate!
      build_selector.validate!
    end

    def create_output_file!
      File.write(File.join(source_dir, output_filename), combined_file)
      puts "Created file (#{output_filename}) from build (##{circle_ci_build.build_num})".green
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

    def circle_ci_branch
      repo.circle_ci_branch
    end

    def circle_ci_build
      build_selector.build
    end

    def build_selector
      @_build_selector ||= Sleet::BuildSelector.new(job_name: job_name, repo: repo)
    end
  end
end
