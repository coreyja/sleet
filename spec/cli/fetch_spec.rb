
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet fetch', type: :cli do
  context 'when NOT in a git repo' do
    it 'fails' do
      expect_command('fetch').to run.unsuccesfully
    end
  end

  context 'when in a git repo' do
    let!(:repo) { Rugged::Repository.init_at('.') }

    it 'fails' do
      expect_command('fetch').to run.unsuccesfully
    end

    context 'with a commit' do
      before do
        oid = repo.write('This is a blob.', :blob)
        index = repo.index
        index.read_tree(repo.head.target.tree) unless repo.empty?
        index.add(path: 'README.md', oid: oid, mode: 0o100644)

        options = {}
        options[:tree] = index.write_tree(repo)

        options[:author] = { email: 'testuser@github.com', name: 'Test Author', time: Time.now }
        options[:committer] = { email: 'testuser@github.com', name: 'Test Author', time: Time.now }
        options[:message] ||= 'Making a commit via Rugged!'
        options[:parents] = repo.empty? ? [] : [repo.head.target].compact
        options[:update_ref] = 'HEAD'

        Rugged::Commit.create(repo, options)
      end

      it 'fails with the correct error message' do
        expect_command('fetch').to run.unsuccesfully.with_stdout('ERROR: No upstream branch set for the current branch of master').with_no_stderr
      end

      context 'when there is a non github upstream' do
        let!(:remote) { repo.remotes.create('origin', 'git://gitlab.com/someuser/somerepo.git') }
        before do
          dirname = File.dirname('.git/refs/remotes/origin/master')
          File.directory?(dirname) || FileUtils.mkdir_p(dirname)
          File.write('.git/refs/remotes/origin/master', repo.head.target.tree_id)
          repo.branches['master'].upstream = repo.branches['origin/master']
        end

        it 'fails with the correct error message' do
          expect_command('fetch').to run.unsuccesfully.with_stdout('ERROR: Upstream remote is not GitHub').with_no_stderr
        end
      end
    end
  end
end
