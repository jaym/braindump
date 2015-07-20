require 'braindump/cookbook_manager'
require 'thor'

module Braindump
  module Command
    class Cookbook < Thor

      desc 'add <org> <repo>', 'Adds a cookbook from Github to run builds against'
      def add(org, repo)
        cookbook_manager = Braindump::CookbookManager.new(parent_options[:home])
        cookbook_manager.add(org, repo)
        say("Added cookbook #{org}/#{repo}")
      end

      desc 'list', 'List the cookbooks being managed'
      def list
        print_table(list_cookbooks)
      end

      private

      def list_cookbooks
        cookbook_manager = Braindump::CookbookManager.new(parent_options[:home])
        cookbooks = cookbook_manager.list

        cookbooks.inject([bold(['org', 'repo', 'path'])]) do |memo, cookbook|
          memo << color_pad([cookbook.org_name, cookbook.repo_name, cookbook.cookbook_path])
        end
      end

      def bold(values)
        values.map do |v|
          shell.set_color(v, :green)
        end
      end

      def color_pad(values)
        values.map do |v|
          v + shell.set_color("", :white)
        end
      end
    end
  end
end
