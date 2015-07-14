require 'braindump/cookbook_manager'
require 'thor'

module Braindump
  module Command
    class Cookbook < Thor

      desc 'add <org> <repo>', 'Adds a cookbook from Github to run builds against'
      def add(org, repo)
        cookbook_manager = Braindump::CookbookManager.new(parent_options[:home])
        cookbook_manager.add(org, repo)
      end
    end
  end
end
