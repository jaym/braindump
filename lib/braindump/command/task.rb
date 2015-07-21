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

      desc 'info <shortname>', 'Display detailed information for a task'
      def info(shortname)
        task_manager = Braindump::Agent.task_manager(parent_options[:home])
        task = task_manager.task_by_shortname(shortname)
        if !task
          error(set_color('Task not found', :red))
          exit(1)
        end

        build = task.name.keys[0]
        cookbook = task.name.keys[1]
        cookbook_sha = task.name.keys[2]
        kitchen_instance = task.name.keys[3]

        print_table([
          ['Build:', set_color(build, :bold, :magenta)],
          ['Cookbook Name:', set_color(cookbook, :bold, :magenta)],
          ['Cookbook Git SHA:', set_color(cookbook_sha, :bold, :magenta)],
          ['Kitchen Instance:', set_color(kitchen_instance, :bold, :magenta)]
        ])


        say('Status:')
        status = task.status

        status_info = case status
                      when Braindump::Status::Failed
                        set_color(status.status_info, :red)
                      when Braindump::Status::Succeeded
                        set_color(status.status_info, :green)
                      else
                        set_color(status.status_info, :red)
                      end
        say_status(status.to_s, status_info)
        say()

        if File.exists?(task.run_file)
          say('run.out:')
          say(File.read(task.run_file))
          say()
        end

        if File.exists?(task.cleanup_file)
          say('cleanup.out:')
          say(File.read(task.cleanup_file))
          say()
        end
      end

      private

      def format_tasks(tasks)
        formatted = [bold(['shortname', 'cookbook', 'sha', 'instance', 'status'])]
        tasks.each do |task|
          keys = task.name.keys[1,3]
          keys[1] = truncate_sha(keys[1])
          formatted << color_pad([task.shortname] + keys + [color_status(task.status)])
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
