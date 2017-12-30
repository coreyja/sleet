require 'pry'

class CRSPFA::Cli < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end

  desc 'do It', 'do'
  def do
    foo = CRSPFA::CurrentBranchGithub.from_dir("#{Dir.home}/Projects/hash_attribute_assignment")

    conn = Faraday.new do |faraday|
      faraday.basic_auth(CRSPFA::CircleCi.instance.token, '')
    end

    url="https://circleci.com/api/v1.1/project/github/#{foo.github_user}/#{foo.github_repo}/latest/artifacts?branch=#{foo.remote_branch}"
    resp = conn.get(url)
    decoded_resp = JSON.parse(resp.body)

    rspec_pers_artificats = decoded_resp.select { |x| x['path'].end_with?('.rspec_example_statuses') }
    urls_to_download = rspec_pers_artificats.map { |x| x['url'] }

    files = urls_to_download.map do |url|
      Faraday.get(url)
    end.map do |resp|
      resp.body
    end

    require 'rspec'; RSpec::Core::ExampleStatusPersister;

    examples = files.flat_map do |file|
      RSpec::Core::ExampleStatusParser.parse(file)
    end.sort_by { |hash| hash[:example_id] }

    dump = RSpec::Core::ExampleStatusDumper.dump(examples)
    p dump
  end
end
