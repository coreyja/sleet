module CRSPFA
  class Foo
    def self.for(dir)
      new Rugged::Repository.new(dir)
    end

    def initialize(repo)
      @repo = repo
    end

    def remote_branch
      current_branch.upstream.name.match(/^([^\/.]+)\/(.+)/)[2]
    end

    def remote_url
      current_branch.remote.url
    end

    private

    attr_reader :repo

    def current_branch
      repo.branches[current_branch_name]
    end

    def current_branch_name
      repo.head.name.sub(/^refs\/heads\//, '')
    end
  end
end
