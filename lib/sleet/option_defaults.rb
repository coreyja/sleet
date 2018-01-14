module Sleet
  class OptionDefaults
    OPTION_FILENAME = '.sleet.yml'.freeze

    def initialize(dir)
      @dir = dir
    end

    def defaults
      defaults_hashes.reduce({}, :merge)
    end

    private

    attr_reader :dir

    def defaults_hashes
      files.map { |f| ::YAML.load_file(f) || {} }
    end

    def files
      files_to_search.select { |f| File.file?(f) }
    end

    def files_to_search
      x.each_index.map do |i|
        (x[0..i] + [OPTION_FILENAME]).join('/')
      end
    end

    def x
      @_x ||= dir.split('/')
    end
  end
end
