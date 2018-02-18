
# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'

describe 'sleet fetch', type: :cli do
  before do
    allow(Sleet::CircleCi.instance).to receive(:token).and_return('FAKE_TOKEN')
  end

  context 'when NOT in a git repo' do
    it 'fails' do
      expect_command('fetch').to raise_error Rugged::RepositoryError
    end
  end

  context 'when in a git repo' do
    let!(:repo) { Rugged::Repository.init_at('.') }

    it 'fails' do
      expect_command('fetch').to raise_error Rugged::ReferenceError
    end

    context 'with a commit' do
      let!(:commit) { create_commit(repo) }

      it 'fails with the correct error message' do
        expect_command('fetch').to error_with 'ERROR: No upstream branch set for the current branch of master'
      end

      context 'when there is a NON github upstream' do
        let!(:remote) { repo.remotes.create('origin', 'git://gitlab.com/someuser/somerepo.git') }
        before { assign_upstream 'master', 'origin/master' }

        it 'runs and outputs the correct error message' do
          expect_command('fetch').to error_with 'ERROR: Upstream remote is not GitHub'
        end
      end

      context 'when there is a github upstream' do
        let!(:remote) { repo.remotes.create('origin', 'git://github.com/someuser/somerepo.git') }
        before { assign_upstream 'master', 'origin/master' }

        let!(:stubbed_branch_request) { stub_request(:get, 'https://circleci.com/api/v1.1/project/github/someuser/somerepo/tree/master').with(query: hash_including('filter' => 'completed')).to_return(body: stubbed_branch_response.to_json) }

        context 'when there are no completed builds found for the branch' do
          let(:stubbed_branch_response) do
            []
          end

          it 'fails with the correct error message' do
            expect_command('fetch').to error_with 'ERROR: No builds with artifcats found'
          end
        end

        context 'when there are only builds without artifacts' do
          let(:stubbed_branch_response) do
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

        context 'when there is a build with artifacts' do
          let(:stubbed_branch_response) do
            [
              {
                has_artifacts: true,
                build_num: 23
              }
            ]
          end
          let!(:stubbed_build_artifact_request) { stub_request(:get, 'https://circleci.com/api/v1.1/project/github/someuser/somerepo/23/artifacts').with(query: hash_including).to_return(body: stubbed_build_artifact_response.to_json) }

          context 'when none of the artifacts end with the correct path' do
            let(:stubbed_build_artifact_response) do
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
            let(:stubbed_build_artifact_response) do
              [
                {
                  path: 'random_file.txt',
                  url: 'BLAH'
                },
                {
                  path: '.rspec_example_statuses',
                  url: 'https://fake_circle_ci_artfiacts.com/some-artifact'
                }
              ]
            end
            let!(:stubbed_single_artifact_request) { stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact').with(query: hash_including).to_return(body: stubbed_single_artifact_response) }
            let(:stubbed_single_artifact_response) do
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

            it 'runs and save the persistance file locally' do
              expect_command('fetch').to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
              expect(File.read('.rspec_example_statuses')).to eq stubbed_single_artifact_response
            end
          end

          context 'when multiple artifacts contain the correct path' do
            let(:stubbed_build_artifact_response) do
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
            let!(:stubbed_single_artifact_1_request) { stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact').with(query: hash_including).to_return(body: stubbed_single_artifact_1_response) }
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
            let!(:stubbed_single_artifact_2_request) { stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact-2').with(query: hash_including).to_return(body: stubbed_single_artifact_2_response) }
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

            let(:combined_artifact_file) do
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

            it 'downloads and combines the artifacts and saves the persistance file locally' do
              expect_command('fetch').to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
              expect(File.read('.rspec_example_statuses')).to eq combined_artifact_file
            end
          end
        end
      end
    end
  end
end
