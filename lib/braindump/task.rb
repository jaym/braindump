require 'braindump/exceptions'
require 'yaml'

module Braindump
  class Task
    attr_reader :task_name, :location, :metadata

    def initialize(task_name, location, metadata={})
      @task_name = task_name
      @metadata = metadata
      @location = location
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

    def status
    end

    def success!
    end

    def fail!
    end

    def self.register(type_name)
      @@types ||= {}
      @@types[type_name.to_sym] = self
    end

    def self.load(spec_file)
      spec_file = File.expand_path(spec_file)
      spec = YAML.load_file(spec_file)
      
      unless spec.has_key?('__type__')
        raise Braindump::MalformedSpec.new("spec files must contain a __type__ parameter")
      end

      unless spec.has_key?('__name__')
        raise Braindump::MalformedSpec.new("spec files must contain a __name__ parameter")
      end

      klass = @@types[spec['__type__'].to_sym]

      unless klass
        raise Braindump::MalformedSpec.new("Unknown type #{specs['__type__']}")
      end

      location = File.expand_path(File.join(spec_file, '..'))

      klass.new(spec['__name__'], location, spec)
    end

    class FooTask < Task
      register :foo
    end
  end
end
