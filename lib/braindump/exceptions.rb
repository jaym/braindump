module Braindump
  class MalformedSpec < Exception
  end

  class InvalidInstance < Exception
  end

  class CookbookNotFound < Exception
    def initialize(org, repo, path)
      super("Could not find cookbook #{org}/#{repo} at #{path}")
    end
  end
end

