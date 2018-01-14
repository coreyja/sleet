# frozen_string_literal: true

module Sleet
  class ArtifactDownloader
    def initialize(artifacts:, file_name:)
      @artifacts = artifacts
      @file_name = file_name
    end

    def files
      @_files ||= urls.map do |url|
        Sleet::CircleCi.get(url)
      end.map(&:body)
    end

    private

    attr_reader :artifacts, :file_name

    def urls
      rspec_artifacts.map { |x| x['url'] }
    end

    def rspec_artifacts
      artifacts.select { |x| x['path'].end_with?(file_name) }
    end
  end
end
