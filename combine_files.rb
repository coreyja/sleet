require 'rspec'; RSpec::Core::ExampleStatusPersister;

dir = ARGV[0]
output_file = ARGV[1]
examples = []

examples = Dir["#{dir}/*"].flat_map do |file_name|
    RSpec::Core::ExampleStatusPersister.load_from(file_name)
end.sort_by { |hash| hash[:example_id] }

dump = RSpec::Core::ExampleStatusDumper.dump(examples)
if output_file
    File.write(output_file, dump)
else
    p dump
end
