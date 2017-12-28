require 'pry'

class CRSPFA::Cli < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end

  desc 'do It', 'do'
  def do
    # puts CRSPFA::CircleCi.instance.token

    repo = Rugged::Repository.new "#{Dir.home}/Projects/hash_attribute_assignment"

    foo = CRSPFA::CurrentBranchGithub.new(repo: repo)

    conn = Faraday.new do |faraday|
      faraday.basic_auth(CRSPFA::CircleCi.instance.token, '')
    end

    project='hash-attribute-assignment'
    remote_branch='circleci-2-builds'
    url="https://circleci.com/api/v1.1/project/github/#{foo.github_user}/#{foo.github_repo}/latest/artifacts?branch=#{foo.remote_branch}"
    p url
    resp = Faraday.get(url)
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
