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

      desc 'list', 'Lists all queued and running tasks'
      def list
        task_manager = Braindump::Agent.task_manager(parent_options[:home])

        tasks = task_manager.running + task_manager.queued
        groups = tasks.group_by { |task| task.name.keys[0] }

        groups.each do |(key, value)|
          say(set_color(key, :bold, :magenta))
          say(set_color('-'*key.length, :bold, :magenta))
          print_table(format_tasks(value))
        end
      end

      private

      def format_tasks(tasks)
        formatted = [bold(['cookbook', 'sha', 'instance', 'status'])]
        tasks.each do |task|
          keys = task.name.keys[1,3]
          keys[1] = truncate_sha(keys[1])
          formatted << color_pad(keys + [color_status(task.status)])
        end
        formatted
      end

      def truncate_sha(sha)
        sha[0,7]
      end

      def bold(values)
        if values.is_a?(Array)
          values.map do |v|
            bold(v)
          end
        else
          shell.set_color(values, :green)
        end
      end

      def color_pad(values)
        values.map do |v|
          v + shell.set_color("", :white)
        end
      end

      def color_status(status)
        status = status.to_s
        case status
        when 'failed'
          set_color(status, :red)
        else
          status
        end
      end

    end
  end
end
