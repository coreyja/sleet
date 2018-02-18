
# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'

describe 'sleet fetch', type: :cli do
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
      before do
        content = "This is a random blob. #{SecureRandom.uuid}"
        filename = 'README.md'
        File.write(filename, content)
        oid = repo.write(content, :blob)
        index = repo.index
        # index.read_tree(repo.head.target.tree) unless repo.empty?
        index.add(path: filename, oid: oid, mode: 0o100644)

        # options = {}
        # options[:tree] = index.write_tree(repo)

        # options[:author] = { email: 'testuser@github.com', name: 'Test Author', time: Time.now }
        # options[:committer] = { email: 'testuser@github.com', name: 'Test Author', time: Time.now }
        # options[:message] ||= 'Making a commit via Rugged!'
        # options[:parents] = repo.empty? ? [] : [repo.head.target].compact
        # options[:update_ref] = 'HEAD'
        author = { email: 'tanoku@gmail.com', time: Time.now, name: 'Vicent Mart' }

        Rugged::Commit.create(repo,
                              author: author,
                              message: 'Hello world',
                              committer: author,
                              parents: [],
                              tree: index.write_tree(repo),
                              update_ref: 'HEAD') #=> "f148106ca58764adc93ad4e2d6b1d168422b9796"

        # Rugged::Commit.create(repo, options)
      end

      it 'fails with the correct error message' do
        expect_command('fetch').to error_with 'ERROR: No upstream branch set for the current branch of master'
      end

      context 'when there is a NON github upstream' do
        let!(:remote) { repo.remotes.create('origin', 'git://gitlab.com/someuser/somerepo.git') }
        before do
          dirname = File.dirname('.git/refs/remotes/origin/master')
          File.directory?(dirname) || FileUtils.mkdir_p(dirname)
          File.write('.git/refs/remotes/origin/master', repo.head.target.tree_id)
          repo.branches['master'].upstream = repo.branches['origin/master']
        end

        it 'runs and outputs the correct error message' do
          expect_command('fetch').to error_with 'ERROR: Upstream remote is not GitHub'
        end
      end

      context 'when there is a github upstream' do
        let!(:remote) { repo.remotes.create('origin', 'git://github.com/someuser/somerepo.git') }
        before do
          dirname = File.dirname('.git/refs/remotes/origin/master')
          File.directory?(dirname) || FileUtils.mkdir_p(dirname)
          File.write('.git/refs/remotes/origin/master', repo.head.target.tree_id)
          repo.branches['master'].upstream = repo.branches['origin/master']
        end

        it 'fails with the correct error message' do
          expect_command('fetch').to error_with 'ERROR: Upstream remote is not GitHub'
        end
      end
    end
  end
end
