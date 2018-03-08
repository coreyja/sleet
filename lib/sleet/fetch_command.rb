# frozen_string_literal: true

module Sleet
  class FetchCommand
    def initialize(config)
      @config = config
    end

    def do!
      repo.validate!
      error_messages = []
      fetchers.map do |fetcher|
        begin
          fetcher.do!
        rescue Sleet::Error => e
          error_messages << e.message
        end
      end
      raise Thor::Error, error_messages.join("\n") unless error_messages.empty?
    end

    private

    attr_reader :config

    def fetchers
      job_name_to_output_files.map do |job_name, output_filename|
        Sleet::JobFetcher.new(
          config: config,
          output_filename: output_filename,
          repo: repo,
          job_name: job_name
        )
      end
    end

    def job_name_to_output_files
      config.workflows || { nil => config.output_file }
    end

    def repo
      @repo ||= Sleet::Repo.from_config(config)
    end
  end
end
