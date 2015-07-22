require 'braindump/agent'
require 'mixlib/versioning'
require 'thor'
require 'pidfile'

module Braindump
  module Command
    class Build < Thor

      desc 'list', 'Lists all available builds'
      def list
        task_manager = Braindump::Agent.task_manager(parent_options[:home])
        task_names = task_manager.task_names
        groups = task_names.group_by { |task| task.keys[0] }
        builds = groups.keys.map { |b| [b] }
        table = [[bold('builds')], *builds]
        print_table(table)
      end

      desc 'status [build_name]', 'Lists info about cookbooks against build'
      def status(build_name=nil)
        task_manager = Braindump::Agent.task_manager(parent_options[:home])
        tasks = task_manager.list(build_name)
        groups = tasks.group_by{|t| t.name.keys[0]}
        builds = groups.keys.map do |v|
          Mixlib::Versioning.parse(v, [
            Mixlib::Versioning::Format::GitDescribe,
            Mixlib::Versioning::Format::OpscodeSemVer,
            Mixlib::Versioning::Format::Rubygems,
            Mixlib::Versioning::Format::SemVer,
          ])
        end.sort.reverse!

        latest_builds = builds[0,3]
        latest_builds.each do |build|
          build = build.to_s
          say(set_color(build, :bold, :magenta))
          say(set_color('-'*build.length, :bold, :magenta))
          print_table(format_tasks(groups[build]))
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
        when 'succeeded'
          set_color(status, :green)
        when 'running'
          set_color(status, :magenta)
        else
          status
        end
      end


    end
  end
end
