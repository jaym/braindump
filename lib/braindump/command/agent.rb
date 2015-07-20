require 'braindump/agent'
require 'thor'

module Braindump
  module Command
    class Agent < Thor

      desc 'start', 'Start the agent'
      def start
        Braindump::Agent.start(parent_options[:home])
      end
    end
  end
end
