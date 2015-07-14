require 'braindump/exceptions'
require 'rugged'

module Braindump
  class CookbookManager
    attr_reader :directory

    def initialize(base_dir)
      @directory = File.expand_path(File.join(base_dir, 'cookbooks'))
    end

    def add(org, repo)
      Cookbook.create(org, repo, cookbook_path(org, repo))
    end

    def get(org, repo)
      path = cookbook_path(org, repo)
      raise CookbookNotFound.new(org, repo, path) unless File.exists?(path)
      Cookbook.load(org, repo, path)
    end

    def list
      files = Dir.entries(directory).reject do |f|
        ['.', '..'].include?(f)
      end

      files.map do |f|
        parts = f.split('#')
        if parts.length != 2
          # TODO: warn
          nil
        else
          Cookbook.load(*parts, cookbook_path(*parts))
        end
      end.reject(&:nil?)
    end

    def cookbook_path(org, repo)
      File.join(directory, "#{org}##{repo}")
    end

    def repository_path(org, repo)
      File.join(cookbook_path(org, repo), 'repo')
    end

  end

  class Cookbook
    attr_reader :org_name, :repo_name, :cookbook_path, :repository

    def initialize(org_name, repo_name, repository, cookbook_path)
      @org_name = org_name
      @repo_name = repo_name
      @cookbook_path = cookbook_path
      @repository = repository
    end

    def self.create(org, repo, cookbook_path)
      FileUtils.mkdir_p(cookbook_path)
      clone_url = "https://github.com/#{org}/#{repo}.git"
      repository = CookbookRepository.clone(clone_url, File.join(cookbook_path, 'repo'), true)
      Cookbook.new(org, repo, repository, cookbook_path).tap do |cookbook|
        cookbook.repository.clone
      end
    end

    def self.load(org, repo, cookbook_path, update_repo=false)
      repository = CookbookRepository.load(File.join(cookbook_path, 'repo'))
      repository.update if update_repo
      Cookbook.new(org, repo, repository, cookbook_path).tap do |cookbook|
        cookbook.repository.update if update_repo
      end
    end
  end

  class CookbookRepository
    attr_reader :path

    def initialize(path)
      @path = File.expand_path(path)
    end

    def exists?
      File.exists?(path)
    end

    def clone_to(new_path)
      cookbook_repo = if bare?
                        CookbookRepository.clone(path, new_path, false)
                      else
                        raise "Can only clone bare repos"
                      end
      cookbook_repo.clone
    end

    def bare?
      repository.bare?
    end

    def head
      ref = repository.head
      ref.target_id
    end

    def update
      origin = repository.remotes['origin']
      origin.fetch('+refs/*:refs/*')
      origin.save
    end

    def self.clone(git_location, path, bare=false)
      path = File.expand_path(path)

      unless File.exists?(path)
        Rugged::Repository.clone_at(git_location, File.expand_path(path), :bare => bare)
      end

      CookbookRepository.new(path)
    end

    def self.load(path)
      CookbookRepository.new(path)
    end

    private

    def repository
      @repository ||= Rugged::Repository.new(path)
    end
  end
end
