require 'braindump/task_queue'
require 'braindump/task_manager'
require 'braindump/logger'
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
      @running_directory = File.join(@directory, 'running')
      @task_manager = Agent::task_manager(base_dir)
    end

    def self.start(base_dir)
      agent = Agent.new(base_dir)
      agent.start_agent
      agent.run
    end

    def run
      while true
        reap_finished
        refresh
        start_new_tasks
        sleep(10)
      end
    end

    def refresh
      last_refresh = time_since_last_refresh
      Logger.info("Time since last refresh: #{last_refresh}")
      if last_refresh < refresh_time
      else
        Logger.info("Starting refresher")
        @time_since_last_refresh = Time.now
        fork_exec("braindump refresh")
      end
    end

    def running_tasks
      entries = Dir.entries(running_directory).reject{|f| f == '.' || f == '..' }
      entries.map do |t|
        Braindump::Task.load(File.join(running_directory, t))
      end
    end

    def reap_finished
      Logger.info('Reaping finished tasks')
      running_tasks.each do |task|
        if task.finished?
          File::unlink(task_location(task))
          Logger.info("Reaping task #{task.name}")
        end
      end
    end

    def start_new_tasks
      empty = false
      while !empty && num_running < max_running
        task = task_queue.dequeue
        if task
          start_task(task)
        else
          empty = true
        end
      end
    end

    def start_task(task)
      location = task_location(task)
      File.symlink(File.expand_path(task.spec_file), location)
      task.running!
      Logger.info("Starting #{task.task_name}")
      fork_exec("braindump task exec #{location}")
    end

    def task_location(task)
      File.expand_path(File.join(running_directory, task.task_name))
    end

    def num_running
      Dir.entries(running_directory).reject{|f| f == '.' || f == '..' }.length
    end

    def max_running
      5
    end

    def time_since_last_refresh
      @time_since_last_refresh ||= Time.now - refresh_time
      Time.now - @time_since_last_refresh
    end

    def refresh_time
      5*60
    end

    def fork_exec(cmd)
      Logger.info("Running #{cmd}")
      pid = Process.fork
      if pid.nil? then
        ObjectSpace.each_object(File) do |f|
          begin
            f.close
          rescue => e
          end
        end
        Process.daemon
        exec(cmd)
      end
    end

    def start_agent
      Logger.info("Starting agent")
      FileUtils.mkdir_p(running_directory)
      @pidfile = PidFile.new(:piddir => directory, :pidfile => 'agent.pid')
    end

    def self.task_manager(base_dir)
      Braindump::TaskManager.new(base_dir)
    end

    private
    def running_directory
      @running_directory
    end

    def task_queue
      @task_manager.task_queue
    end

  end
end

