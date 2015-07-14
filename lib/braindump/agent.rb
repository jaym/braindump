require 'pidfile'

module Braindump
  # The agent is responsible for supervising the execution
  # of all kitchen instances. It will be automatically
  # launched as a daemon process. There can only be one agent
  # running at a given time.
  class Agent
    attr_reader :directory

    def initialize(base_dir)
      @directory = File.expand_path(File.join(base_dir, 'agent'))
    end

    def self.start(base_dir)
      agent = Agent.new(base_dir)
      agent.start_agent
      agent
    end

    def start_agent
      FileUtils.mkdir_p(directory)
      FileUtils.mkdir_p(File.join(directory, jobs))
      @pidfile = PidFile.new(:piddir => directory, :pidfile => 'agent.pid')
    end

  end
end

