require 'braindump/task_queue'
require 'braindump/task_manager'
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
    end

    def running_tasks
      entries = Dir.entries(running_directory).reject{|f| f == '.' || f == '..' }
      entries.map do |t|
        Braindump::Task.load(File.join(running_directory, t))
      end
    end

    def reap_finished
      running_tasks.each do |task|
        if task.finished?
          File::unlink(task_location(task))
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
      puts "Starting #{task.task_name}"
      pid = Process.fork
      if pid.nil? then
        ObjectSpace.each_object(File) do |f|
          begin
            f.close
          rescue => e
          end
        end
        exec("braindump task exec #{location}")
      else
        Process.detach(pid)
      end
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

    def start_agent
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

