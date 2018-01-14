module Sleet
  class RspecFileMerger
    def initialize(files)
      @files = files
    end

    def output
      RSpec::Core::ExampleStatusDumper.dump(sorted_examples)
    end

    private

    attr_reader :files

    def sorted_examples
      examples.sort_by { |hash| hash[:example_id] }
    end

    def examples
      files.flat_map do |file|
        RSpec::Core::ExampleStatusParser.parse(file)
      end
    end
  end
end
