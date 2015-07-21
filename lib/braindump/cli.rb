require 'braindump'
require 'braindump/refresher'
require 'braindump/command/cookbook'
require 'braindump/command/task'
require 'braindump/command/agent'
require 'braindump/command/build'
require 'braindump/logger'
require 'braindump/agent'
require 'braindump/mixin/forks'
require 'thor'

module Braindump
  class CLI < Thor
    include Braindump::Mixin::Forks

    DEFAULT_HOME = '~/.braindump'

    class_option :home, :type => :string, :default => DEFAULT_HOME
    class_option :auto, :type => :boolean, :default => true

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
        if !options[:auto] or Braindump::Agent.running?(options[:home])
          Braindump::Refresher.new(options[:home]).run
        else
          fork_exec("braindump agent start --home #{options[:home]}")
        end
      rescue => e
        Logger.error(e)
        raise
      end
    end
  end
end
