# frozen_string_literal: true

module Sleet
  class ArtifactDownloader
    def initialize(circle_ci_token:, artifacts:, file_name:)
      @circle_ci_token = circle_ci_token
      @artifacts = artifacts
      @file_name = file_name
    end

    def files
      @files ||= urls.map do |url|
        Sleet::CircleCi.get(url, circle_ci_token)
      end.map(&:body)
    end

    private

    attr_reader :artifacts, :file_name, :circle_ci_token

    def urls
      rspec_artifacts.map { |x| x['url'] }
    end

    def rspec_artifacts
      artifacts.select { |x| x['path'].end_with?(file_name) }
    end
  end
end
