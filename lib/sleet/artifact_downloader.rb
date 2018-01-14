module Sleet
  class ArtifactDownloader
    def initialize(artifacts)
      @artifacts = artifacts
    end

    def files
      @_files ||= urls.map do |url|
        Sleet::CircleCi.get(url)
      end.map(&:body)
    end

    private

    attr_reader :artifacts

    def urls
      rspec_artifacts.map { |x| x['url'] }
    end

    def rspec_artifacts
      artifacts.select { |x| x['path'].end_with?('.rspec_example_statuses') }
    end
  end
end
