# frozen_string_literal: true

module GitHelper
  def create_commit(repo)
    content = "This is a random blob. #{SecureRandom.uuid}"
    filename = 'README.md'
    File.write(filename, content)
    oid = repo.write(content, :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree) unless repo.empty?
    index.add(path: filename, oid: oid, mode: 0o100644)
    author = { email: 'tanoku@gmail.com', time: Time.now, name: 'Vicent Mart' }

    Rugged::Commit.create(repo,
                          author: author,
                          message: 'Hello world',
                          committer: author,
                          parents: repo.empty? ? [] : [repo.head.target].compact,
                          tree: index.write_tree(repo),
                          update_ref: 'HEAD')
  end

  def assign_upstream(local_branch, remote_branch)
    path = ".git/refs/remotes/#{remote_branch}"
    dirname = File.dirname(path)
    File.directory?(dirname) || FileUtils.mkdir_p(dirname)
    File.write(path, repo.head.target.tree_id)
    repo.branches[local_branch].upstream = repo.branches[remote_branch]
  end
end
