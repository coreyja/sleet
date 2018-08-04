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
    stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/tree/.+})
      .with(query: { 'circle-token' => 'FAKE_TOKEN', 'filter' => 'completed' })
      .to_return(body: branch_response.to_json)
  end
  let(:stubbed_build_request) do
    stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/\d+/artifacts})
      .with(query: { 'circle-token' => 'FAKE_TOKEN' })
      .to_return(body: build_response.to_json)
  end
  let(:stubbed_artifact_request) do
    stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact')
      .with(query: { 'circle-token' => 'FAKE_TOKEN' })
      .to_return(body: artifact_response)
  end

  let(:create_repo?) { true }
  let(:repo_directory) { Dir.pwd }
  let(:repo) { Rugged::Repository.init_at(repo_directory) }
  let(:remote) { repo.remotes.create('origin', 'git://github.com/someuser/somerepo.git') }

  let(:yaml_options) { { circle_ci_token: 'FAKE_TOKEN' } }

  before do
    File.write('.sleet.yml', yaml_options.to_yaml)
    stubbed_branch_request
    stubbed_build_request
    stubbed_artifact_request

    repo
    create_commit(repo)

    remote
    assign_upstream repo, 'master', 'origin/master'
  end

  it 'downloads and saves the persistance file locally' do
    expect_command('fetch').to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
    expect(File.read('.rspec_example_statuses')).to eq happy_path_final_file
    expect(stubbed_branch_request).to have_been_made.once
    expect(stubbed_build_request).to have_been_made.once
  end

  context 'when the circleci token is missing from the yml file' do
    let(:yaml_options) { {} }

    it 'errors about the missing token' do
      expect_command('fetch')
        .to error_with('ERROR: circle_ci_token required and not provided')
        .and output_nothing.to_stdout
    end
  end

  context 'when NOT in a git repo' do
    let(:repo_directory) { Dir.mktmpdir }

    it 'fails when a source is not provided' do
      expect_command('fetch').to raise_error Rugged::RepositoryError
    end

    it 'succeeds when given the source path as an option' do
      expect_command("fetch --source-dir #{repo_directory}")
        .to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read("#{repo_directory}/.rspec_example_statuses")).to eq happy_path_final_file
    end
  end

  context 'when there is a NON github upstream' do
    let(:remote) { repo.remotes.create('origin', 'git://gitlab.com/someuser/somerepo.git') }

    before { assign_upstream repo, 'master', 'origin/master' }

    it 'runs and outputs the correct error message' do
      expect_command('fetch').to error_with 'ERROR: Upstream remote is not GitHub'
    end

    it 'runs with multiple workflows and only outputs the error once' do
      expect_command('fetch --workflows a:a b:b').to error_with 'ERROR: Upstream remote is not GitHub'
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

  context 'when none of the artifacts end with the default path' do
    let(:build_response) do
      [
        {
          path: 'random_file.txt',
          url: 'https://fake_circle_ci_artfiacts.com/some-artifact'
        }
      ]
    end

    it 'runs and creates an empty file for the persistance status file' do
      expect_command('fetch')
        .to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_statuses').strip).to eq ''
    end

    it 'creates the correct file when given the correct short hand input file option' do
      expect_command('fetch -i random_file.txt')
        .to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_statuses')).to eq happy_path_final_file
    end
    it 'creates the correct file when given the correct input file option' do
      expect_command('fetch --input-file random_file.txt')
        .to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_statuses')).to eq happy_path_final_file
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
      expect_command('fetch')
        .to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
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
    let(:stubbed_single_artifact_1_request) do
      stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact')
        .with(query: hash_including)
        .to_return(body: stubbed_single_artifact_1_response)
    end
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
    let(:stubbed_single_artifact_2_request) do
      stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-artifact-2')
        .with(query: hash_including)
        .to_return(body: stubbed_single_artifact_2_response)
    end
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
      expect_command('fetch')
        .to output('Created file (.rspec_example_statuses) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_statuses')).to eq happy_path_final_file
    end
  end

  it 'respects the output file CLI option' do
    expect_command('fetch --output-file some_cool_file.txt')
      .to output('Created file (some_cool_file.txt) from build (#23)'.green + "\n").to_stdout.and without_error
    expect(File.read('some_cool_file.txt')).to eq happy_path_final_file
  end
  it 'respects the shortened output file CLI option' do
    expect_command('fetch -o some_cool_file.txt')
      .to output('Created file (some_cool_file.txt) from build (#23)'.green + "\n").to_stdout.and without_error
    expect(File.read('some_cool_file.txt')).to eq happy_path_final_file
  end

  context 'when the repo uses workflows' do
    let(:branch_response) do
      [
        { has_artifacts: true, build_num: 14, workflows: { job_name: 'prep-job' } },
        { has_artifacts: true, build_num: 23, workflows: { job_name: 'rspec-job' } },
        { has_artifacts: true, build_num: 509, workflows: { job_name: 'other-random-job' } }
      ]
    end

    it 'works when given the rspec job and a single output' do
      expect_command('fetch --workflows rspec-job:.rspec_example_file')
        .to output('Created file (.rspec_example_file) from build (#23)'.green + "\n").to_stdout
      expect(File.read('.rspec_example_file')).to eq happy_path_final_file
    end

    context 'when used in a mono-repo' do
      let(:branch_response) do
        [
          { has_artifacts: true, build_num: 14, workflows: { job_name: 'some-app-rspec' } },
          { has_artifacts: true, build_num: 23, workflows: { job_name: 'app-rspec' } },
          { has_artifacts: true, build_num: 509, workflows: { job_name: 'third-app-rspec' } }
        ]
      end
      let(:build_response_thrid_app) do
        [
          {
            path: '.rspec_example_statuses',
            url: 'https://fake_circle_ci_artfiacts.com/third-app-artifact'
          }
        ]
      end
      let(:build_response_some_app) do
        [
          {
            path: '.rspec_example_statuses',
            url: 'https://fake_circle_ci_artfiacts.com/some-app-artifact'
          }
        ]
      end
      let(:third_artifact_response) do
        <<~ARTIFACT
          example_id                             | status | run_time        |
          -------------------------------------- | ------ | --------------- |
          ./spec/model/taco_spec.rb[1:3]         | passed | 0.00111 seconds |
        ARTIFACT
      end
      let(:some_artifact_response) do
        <<~ARTIFACT
          example_id                               | status | run_time        |
          ---------------------------------------- | ------ | --------------- |
          ./spec/model/random_spec.rb[1:1]         | passed | 0.00073 seconds |
        ARTIFACT
      end
      let(:stubbed_build_14_request) do
        stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/14/artifacts})
          .with(query: hash_including)
          .to_return(body: build_response.to_json)
      end
      let(:stubbed_artifact_14_request) do
        stub_request(:get, 'https://fake_circle_ci_artfiacts.com/some-app-artifact')
          .with(query: hash_including)
          .to_return(body: artifact_response)
      end
      let(:stubbed_build_509_request) do
        stub_request(:get, %r{https://circleci.com/api/v1.1/project/github/.+/.+/509/artifacts})
          .with(query: hash_including)
          .to_return(body: build_response.to_json)
      end
      let(:stubbed_artifact_509_request) do
        stub_request(:get, 'https://fake_circle_ci_artfiacts.com/third-app-artifact')
          .with(query: hash_including)
          .to_return(body: artifact_response)
      end
      let(:expected_output) do
        'Created file (app/.rspec_example_file) from build (#23)'.green + "\n" +
          'Created file (some_app/.rspec_example_status) from build (#14)'.green + "\n" +
          'Created file (third_app/rspec.txt) from build (#509)'.green + "\n"
      end

      before do
        stubbed_build_14_request
        stubbed_artifact_14_request
        stubbed_build_509_request
        stubbed_artifact_509_request

        Dir.mkdir('app')
        Dir.mkdir('some_app')
        Dir.mkdir('third_app')
      end

      it 'works when given the rspec job and a single output' do
        expect_command('fetch --workflows app-rspec:app/.rspec_example_file
                       some-app-rspec:some_app/.rspec_example_status
                       third-app-rspec:third_app/rspec.txt')
          .to output(expected_output).to_stdout
        expect(File.read('app/.rspec_example_file')).to eq happy_path_final_file
        expect(File.read('some_app/.rspec_example_status')).to eq happy_path_final_file
        expect(File.read('third_app/rspec.txt')).to eq happy_path_final_file
        expect(stubbed_branch_request).to have_been_made.once
      end

      context 'when using a config file for the options' do
        let(:yaml_options) do
          {
            circle_ci_token: 'FAKE_TOKEN',
            workflows: {
              'app-rspec' => 'app/.rspec_example_file',
              'some-app-rspec' => 'some_app/.rspec_example_status',
              'third-app-rspec' => 'third_app/rspec.txt'
            }
          }
        end

        it 'works when given the rspec job and a single output' do
          expect_command('fetch')
            .to output(expected_output).to_stdout
          expect(File.read('app/.rspec_example_file')).to eq happy_path_final_file
          expect(File.read('some_app/.rspec_example_status')).to eq happy_path_final_file
          expect(File.read('third_app/rspec.txt')).to eq happy_path_final_file
        end
      end
    end
  end
end
