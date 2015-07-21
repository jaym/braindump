require 'braindump/agent'
require 'braindump/logger'
require 'thor'

module Braindump
  module Command
    class Agent < Thor

      desc 'start', 'Start the agent'
      def start
        Braindump::Logger.init(File.expand_path(File.join(options[:home], 'log')))
        Braindump::Logger.level = :debug
        begin
          Braindump::Agent.start(parent_options[:home])
        rescue => e
          Logger.error(e)
          raise
        end

      end
    end
  end
end
