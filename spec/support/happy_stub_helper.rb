
# frozen_string_literal: true

module HappyStubHelper
  def setup_happy_path!
    happy_git!
    happy_circle!
  end

  private

  def happy_circle!
    stub_branch
    stub_build
    stub_artifact
  end

  def stub_branch
    stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/tree/.+}).with(query: hash_including).to_return(body: branch_response.to_json)
  end

  def stub_build
    stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/\d+/artifacts}).with(query: hash_including).to_return(body: build_response.to_json)
  end

  def stub_artifact
    stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact').with(query: hash_including).to_return(body: artifact_response)
  end

  def branch_response
    [{ has_artifacts: true, build_num: 23 }]
  end

  def build_response
    [
      {
        path: '.rspec_example_statuses',
        url: 'https://fake_circle_ci_artfiacts.com/some-artifact'
      }
    ]
  end

  def artifact_response
    <<~ARTIFACT
      example_id                              | status | run_time        |
      --------------------------------------- | ------ | --------------- |
      ./spec/cli/fetch_spec.rb[1:1:1]         | passed | 0.00912 seconds |
      ./spec/cli/fetch_spec.rb[1:2:1]         | passed | 0.0078 seconds  |
      ./spec/cli/fetch_spec.rb[1:2:2:1]       | passed | 0.01431 seconds |
      ./spec/cli/fetch_spec.rb[1:2:2:2:1]     | passed | 0.0193 seconds  |
      ./spec/cli/fetch_spec.rb[1:2:2:3:1:1]   | passed | 0.03077 seconds |
      ./spec/cli/fetch_spec.rb[1:2:2:3:2:1]   | passed | 0.02891 seconds |
      ./spec/cli/fetch_spec.rb[1:2:2:3:3:1:1] | passed | 0.03863 seconds |
      ./spec/cli/fetch_spec.rb[1:2:2:3:3:2:1] | passed | 0.05603 seconds |
      ./spec/cli/version_spec.rb[1:1]         | passed | 0.00165 seconds |
      ./spec/model/circle_ci_spec.rb[1:1:1]   | passed | 0.00814 seconds |
      ./spec/model/sleet_spec.rb[1:1]         | passed | 0.00073 seconds |
    ARTIFACT
  end
  alias happy_path_final_file artifact_response

  def happy_git!
    repo = Rugged::Repository.init_at('.')
    create_commit(repo)
    repo.remotes.create('origin', 'git://github.com/someuser/somerepo.git')
    assign_upstream repo, 'master', 'origin/master'
  end
end
