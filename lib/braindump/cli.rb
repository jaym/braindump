require 'braindump'
require 'braindump/refresher'
require 'braindump/command/cookbook'
require 'thor'

module Braindump
  class CLI < Thor
    DEFAULT_HOME = '~/.braindump'

    class_option :home, :type => :string, :default => DEFAULT_HOME

    desc 'cookbook SUBCOMMAND ...ARGS', 'manage the tracked cookbooks'
    subcommand 'cookbook', Braindump::Command::Cookbook

    desc 'refresh', 'fetch latest chef build and cookbooks'
    def refresh
      Braindump::Refresher.new(options[:home]).run
    end

  end
end
