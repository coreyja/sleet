# frozen_string_literal: true

module GitHelper
  def create_commit(repo)
    index = add_file_to_index(repo)

    Rugged::Commit.create(repo,
                          author: fake_author,
                          message: 'Hello world',
                          committer: fake_author,
                          parents: repo.empty? ? [] : [repo.head.target].compact,
                          tree: index.write_tree(repo),
                          update_ref: 'HEAD')
  end

  def assign_upstream(repo, local_branch, remote_branch)
    path = "#{repo.path}/refs/remotes/#{remote_branch}"
    dirname = File.dirname(path)
    File.directory?(dirname) || FileUtils.mkdir_p(dirname)
    File.write(path, repo.head.target.tree_id)
    repo.branches[local_branch].upstream = repo.branches[remote_branch]
  end

  def remove_upstream(repo, local_branch)
    repo.branches[local_branch].upstream = nil
  end

  private

  def add_file_to_index(repo)
    content = "This is a random blob. #{SecureRandom.uuid}"
    filename = 'README.md'
    oid = repo.write(content, :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree) unless repo.empty?
    index.add(path: filename, oid: oid, mode: 0o100644)
    index
  end

  def fake_author
    { email: 'email@example.com', time: Time.now, name: 'Person' }
  end
end
