require 'braindump/agent'
require 'thor'

module Braindump
  module Command
    class Agent < Thor

      desc 'start', 'Start the agent'
      def start
        Braindump::Logger.init(File.expand_path(File.join(options[:home], 'log')))
        Braindump::Logger.level = :debug
        Braindump::Agent.start(parent_options[:home])
      end
    end
  end
end
