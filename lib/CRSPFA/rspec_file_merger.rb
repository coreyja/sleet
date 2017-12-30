class CRSPFA::RspecFileMerger


  def initialize(files)
    @files = files
  end

  def output
    RSpec::Core::ExampleStatusDumper.dump(examples)
  end

  private

  attr_reader :files

  def examples
    files.flat_map do |file|
      RSpec::Core::ExampleStatusParser.parse(file)
    end.sort_by { |hash| hash[:example_id] }
  end
end
