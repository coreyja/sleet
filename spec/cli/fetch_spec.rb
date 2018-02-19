
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet fetch', type: :cli do
  let(:branch_response) do
    [{ has_artifacts: true, build_num: 23 }]
  end
  let(:build_response) do
    [
      {
        path: '.rspec_example_statuses',
        url: 'https://fake_circle_ci_artfiacts.com/some-artifact'
      }
    ]
  end
  let(:artifact_response) do
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
  let(:happy_path_final_file)  { artifact_response }
  let(:stubbed_branch_request) do
    stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/tree/.+}).with(query: hash_including).to_return(body: branch_response.to_json)
  end
  let(:stubbed_build_request) do
    stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/\d+/artifacts}).with(query: hash_including).to_return(body: build_response.to_json)
  end
  let(:stubbed_artifact_request) do
    stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact').with(query: hash_including).to_return(body: artifact_response)
  end

  let(:create_repo?) { true }
  let(:repo) { Rugged::Repository.init_at('.') }
  let(:remote) { repo.remotes.create('origin', 'git://github.com/someuser/somerepo.git') }

  before do
    allow(Sleet::CircleCi.instance).to receive(:token).and_return('FAKE_TOKEN')
    stubbed_branch_request
    stubbed_build_request
    stubbed_artifact_request

    if create_repo?
      repo
      create_commit(repo)

      remote
      assign_upstream repo, 'master', 'origin/master'
    end
  end

  it 'downloads and saves the persistance file locally' do
    expect_command('fetch').to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
    expect(File.read('.rspec_example_statuses')).to eq happy_path_final_file
  end

  context 'when NOT in a git repo' do
    let(:create_repo?) { false }

    it 'fails' do
      expect_command('fetch').to raise_error Rugged::RepositoryError
    end
  end

  context 'when there is a NON github upstream' do
    let(:remote) { repo.remotes.create('origin', 'git://gitlab.com/someuser/somerepo.git') }

    before { assign_upstream repo, 'master', 'origin/master' }

    it 'runs and outputs the correct error message' do
      expect_command('fetch').to error_with 'ERROR: Upstream remote is not GitHub'
    end
  end

  context 'when there are no completed builds found for the branch' do
    let(:branch_response) do
      []
    end

    it 'fails with the correct error message' do
      expect_command('fetch').to error_with 'ERROR: No builds with artifcats found'
    end
  end

  context 'when there are only builds without artifacts' do
    let(:branch_response) do
      [
        {
          has_artifacts: false,
          build_num: 23
        }
      ]
    end

    it 'fails with the correct error message' do
      expect_command('fetch').to error_with 'ERROR: No builds with artifcats found'
    end
  end

  context 'when none of the artifacts end with the correct path' do
    let(:build_response) do
      [
        {
          path: 'random_file.txt',
          url: 'BLAH'
        }
      ]
    end

    it 'runs and creates an empty file for the persistance status file' do
      expect_command('fetch').to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_statuses').strip).to eq ''
    end
  end

  context 'when one of the artifacts end with the correct path' do
    let(:build_response) do
      [
        {
          path: 'random_file.txt',
          url: 'fake_url.com/fake_path'
        },
        {
          path: '.rspec_example_statuses',
          url: 'https://fake_circle_ci_artfiacts.com/some-artifact'
        }
      ]
    end

    it 'runs and save the persistance file locally' do
      expect_command('fetch').to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_statuses')).to eq happy_path_final_file
    end
  end

  context 'when multiple artifacts contain the correct path' do
    let(:build_response) do
      [
        {
          path: 'random_file.txt',
          url: 'BLAH'
        },
        {
          path: '.rspec_example_statuses',
          url: 'https://fake_circle_ci_artfiacts.com/some-artifact'
        },
        {
          path: '.rspec_example_statuses',
          url: 'https://fake_circle_ci_artfiacts.com/some-artifact-2'
        }
      ]
    end
    let(:stubbed_single_artifact_1_request) { stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact').with(query: hash_including).to_return(body: stubbed_single_artifact_1_response) }
    let(:stubbed_single_artifact_1_response) do
      <<~ARTIFACT
        example_id                              | status | run_time        |
        --------------------------------------- | ------ | --------------- |
        ./spec/cli/fetch_spec.rb[1:2:2:3:3:2:1] | passed | 0.05603 seconds |
        ./spec/model/circle_ci_spec.rb[1:1:1]   | passed | 0.00814 seconds |
        ./spec/cli/fetch_spec.rb[1:2:2:2:1]     | passed | 0.0193 seconds  |
        ./spec/cli/fetch_spec.rb[1:2:2:3:1:1]   | passed | 0.03077 seconds |
        ./spec/cli/fetch_spec.rb[1:2:2:3:2:1]   | passed | 0.02891 seconds |
        ./spec/cli/fetch_spec.rb[1:2:2:3:3:1:1] | passed | 0.03863 seconds |
              ARTIFACT
    end
    let(:stubbed_single_artifact_2_request) { stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact-2').with(query: hash_including).to_return(body: stubbed_single_artifact_2_response) }
    let(:stubbed_single_artifact_2_response) do
      <<~ARTIFACT
        example_id                        | status | run_time        |
        --------------------------------- | ------ | --------------- |
        ./spec/cli/fetch_spec.rb[1:1:1]   | passed | 0.00912 seconds |
        ./spec/cli/fetch_spec.rb[1:2:1]   | passed | 0.0078 seconds  |
        ./spec/cli/fetch_spec.rb[1:2:2:1] | passed | 0.01431 seconds |
        ./spec/model/sleet_spec.rb[1:1]   | passed | 0.00073 seconds |
        ./spec/cli/version_spec.rb[1:1]   | passed | 0.00165 seconds |
              ARTIFACT
    end

    before do
      stubbed_single_artifact_1_request
      stubbed_single_artifact_2_request
    end

    it 'downloads and combines the artifacts and saves the persistance file locally' do
      expect_command('fetch').to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_statuses')).to eq happy_path_final_file
    end
  end
end
