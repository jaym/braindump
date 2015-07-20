require 'braindump/exceptions'
require 'braindump/status'
require 'braindump/task_name'
require 'yaml'

module Braindump
  class Task
    attr_reader :task_name, :location, :metadata

    def initialize(task_name, location, metadata={})
      @task_name = task_name
      @metadata = metadata
      @location = location
    end

    def name
      Braindump::TaskName.new(task_name)
    end

    def run
      raise "Must override run"
    end

    def cleanup
      raise "Must override cleanup"
    end

    def run_file
      File.join(location, 'run.out')
    end

    def cleanup_file
      File.join(location, 'cleanup.out')
    end

    def spec_file
      File.join(location, 'task.spec')
    end

    def status_file
      File.join(location, 'status')
    end

    def pid_file
      File.join(location, 'running.pid')
    end

    def execute
      pid = PidFile.new(:piddir => File.dirname(pid_file), :pidfile => File.basename(pid_file))
      begin
        begin
          run
          success!
        rescue => e
          fail!(e.to_s)
          raise
        ensure
          cleanup
        end
      ensure
        pid.release
      end
    end

    def status
      Braindump::Status.from_file(status_file)
    end

    def success!(msg="")
      Braindump::Status.to_file(Braindump::Status::Succeeded.new(msg), status_file)
    end

    def fail!(msg="")
      Braindump::Status.to_file(Braindump::Status::Failed.new(msg), status_file)
    end

    def queued!(msg="")
      Braindump::Status.to_file(Braindump::Status::Queued.new(msg), status_file)
    end

    def running!(msg="")
      Braindump::Status.to_file(Braindump::Status::Running.new(msg), status_file)
    end

    def finished?
      case status
      when Braindump::Status::Failed, Braindump::Status::Succeeded
        true
      when Braindump::Status::Running
        PidFile.running?(pid_file)
      else
        false
      end
    end

    def self.register(type_name)
      @@types ||= {}
      @@types[type_name.to_sym] = self
    end

    def self.load(spec_file)
      spec_file = File.expand_path(spec_file)
      if File.symlink?(spec_file)
        spec_file = File.readlink(spec_file)
      end
      location = File.expand_path(File.join(spec_file, '..'))

      spec = YAML.load_file(spec_file)

      unless spec.has_key?('__type__')
        raise Braindump::MalformedSpec.new("spec files must contain a __type__ parameter")
      end

      unless spec.has_key?('__name__')
        raise Braindump::MalformedSpec.new("spec files must contain a __name__ parameter")
      end

      klass = @@types[spec['__type__'].to_sym]

      unless klass
        raise Braindump::MalformedSpec.new("Unknown type #{spec['__type__']}")
      end

      klass.new(spec['__name__'], location, spec)
    end

    class FooTask < Task
      register :foo
    end
  end
end
