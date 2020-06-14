# frozen_string_literal: true

module Sleet
  class JobFetcher
    def initialize(config:, output_filename:, job_name:, repo:)
      @circle_ci_token = config.circle_ci_token
      @source_dir = config.source_dir
      @input_filename = config.input_file
      @output_filename = output_filename
      @job_name = job_name
      @repo = repo
    end

    def do!
      validate!
      create_output_file!
    end

    private

    attr_reader :input_filename, :output_filename, :job_name, :source_dir, :repo, :circle_ci_token

    def validate!
      build_selector.validate!
    end

    def create_output_file!
      File.write(File.join(source_dir, output_filename), combined_file)
      puts "Created file (#{output_filename}) from build (##{build.build_num})".green
    end

    def combined_file
      Sleet::RspecFileMerger.new(build_persistance_artifacts).output
    end

    def build_persistance_artifacts
      @build_persistance_artifacts ||= Sleet::ArtifactDownloader.new(
        file_name: input_filename,
        artifacts: build.artifacts,
        circle_ci_token: circle_ci_token
      ).files
    end

    def build
      build_selector.build
    end

    def build_selector
      @build_selector ||= Sleet::BuildSelector.new(job_name: job_name, repo: repo)
    end
  end
end
