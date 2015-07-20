require 'braindump/task'
require 'thor'
require 'pidfile'

module Braindump
  module Command
    class Task < Thor

      desc 'exec <task_spec>', 'Runs a task'
      def exec(task_spec)
        task = Braindump::Task.load(task_spec)
        task.execute
      end
    end
  end
end
