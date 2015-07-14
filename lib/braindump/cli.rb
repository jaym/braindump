require 'braindump'
require 'braindump/command/cookbook'
require 'thor'

module Braindump
  class CLI < Thor
    DEFAULT_HOME = '~/.braindump'

    class_option :home, :type => :string, :default => DEFAULT_HOME

    desc 'cookbook SUBCOMMAND ...ARGS', 'manage the tracked cookbooks'
    subcommand 'cookbook', Braindump::Command::Cookbook
  end
end
