require 'braindump/task_name'

module Braindump
  class TaskManager
    def initialize(base_dir)
      base_dir = File.expand_path(base_dir)
      @queued_dir = File.join(base_dir, 'task_manager', 'queued')
      @running_dir = File.join(base_dir, 'task_manager', 'running')
      @registered_dir = File.join(base_dir, 'task_manager', 'registered')
      @shortname_dir = File.join(base_dir, 'task_manager', 'shortname')
      @task_queue = Braindump::TaskQueue.from_directory(queued_dir)
    end

    def register(task, enqueue=true)
      task_name = task.name
      keys = task_name.keys
      dir = File.join(registered_dir, *keys[0,keys.length-1])
      FileUtils.mkdir_p(dir)

      # TODO: Needs locking
      task_location = File.join(dir, keys[-1])
      if File.exists?(task_location)
        false
      else
        File.symlink(task.spec_file, task_location)
        if enqueue
          id = task_queue.queue(task)
          FileUtils.mkdir_p(shortname_dir)
          shortname_location = File.join(shortname_dir, id)
          File.symlink(task.spec_file, shortname_location)
          task.shortname(id)
        end
        true
      end
    end

    def list(pattern=nil)
      task_names = Dir[File.join(registered_dir, '**/*')].select{|f| File.file? f}

      matching = if pattern
                   task_names.select {|task_name| task_name =~ pattern }
                 else
                   task_names
                 end

      matching.map do |t|
        load_link(t)
      end
    end

    def task_names(pattern=nil)
      reg_dir = Pathname.new(registered_dir)
      task_names = Dir[File.join(registered_dir, '**/*')].select{|f| File.file? f}.map do |f|
        task_name = Pathname.new(f).relative_path_from(reg_dir).to_s
        Braindump::TaskName.new(task_name)
      end

      matching = if pattern
                   task_names.select {|task_name| task_name.to_s =~ pattern }
                 else
                   task_names
                 end
    end

    def running
      task_names = Dir[File.join(running_dir, '*')]

      task_names.map do |t|
        load_link(t)
      end
    end

    def queued
      task_queue.list
    end

    def task_queue
      @task_queue
    end

    private

    def queued_dir
      @queued_dir
    end

    def running_dir
      @running_dir
    end

    def registered_dir
      @registered_dir
    end

    def shortname_dir
      @shortname_dir
    end

    def load_link(link_path)
      real_path = File.readlink(link_path)
      Braindump::Task.load(real_path)
    end
  end
end
