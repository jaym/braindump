require 'braindump'
require 'braindump/refresher'
require 'braindump/command/cookbook'
require 'braindump/command/task'
require 'braindump/command/agent'
require 'braindump/command/build'
require 'braindump/logger'
require 'thor'

module Braindump
  class CLI < Thor
    DEFAULT_HOME = '~/.braindump'

    class_option :home, :type => :string, :default => DEFAULT_HOME

    desc 'cookbook SUBCOMMAND ...ARGS', 'manage the tracked cookbooks'
    subcommand 'cookbook', Braindump::Command::Cookbook

    desc 'task SUBCOMMAND ...ARGS', 'manage tasks'
    subcommand 'task', Braindump::Command::Task

    desc 'agent SUBCOMMAND ...ARGS', 'manage the agent'
    subcommand 'agent', Braindump::Command::Agent

    desc 'build SUBCOMMAND ...ARGS', 'manage the chef builds'
    subcommand 'build', Braindump::Command::Build

    desc 'refresh', 'fetch latest chef build and cookbooks'
    option :log, :type => :string
    def refresh
      Braindump::Logger.init(File.expand_path(File.join(options[:home], 'log')))
      Braindump::Logger.level = :debug
      begin
        Braindump::Refresher.new(options[:home]).run
      rescue => e
        Logger.error(e)
        raise
      end
    end

  end
end
