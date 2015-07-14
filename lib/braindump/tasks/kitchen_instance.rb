require 'braindump/task'
require 'braindump/exceptions'
require 'mixlib/shellout'
require 'logger'
require 'yaml'

module Braindump
  class KitchenInstanceTask < Task
    register :kitchen_instance

    PLATFORM_NAMES = [
      'ubuntu-10.04',
      'ubuntu-12.04',
      'ubuntu-12.10',
      'ubuntu-13.04',
      'ubuntu-13.10',
      'ubuntu-14.04',
      'centos-6.4',
      'debian-7.1.0',
      'windows-2012r2',
      'windows-2008r2'
    ]

    PLATFORMS = PLATFORM_NAMES.map do |p|
      {'name' => p}
    end


    def run
      Dir.chdir(File.join(location, 'cookbook')) do
        logger = Logger.new(run_file)
        begin
          kitchen_test = Mixlib::ShellOut.new('kitchen test', :live_stream => logger, :env => environment, :timeout => 3600)
          kitchen_test.run_command
          if kitchen_test.error?
            kitchen_test.error!
          end
        ensure
          logger.close
        end
      end
    end

    def cleanup
      Dir.chdir(File.join(location, 'cookbook')) do
        logger = Logger.new(cleanup_file)
        begin
          kitchen_destroy = Mixlib::ShellOut.new('kitchen destroy', :live_stream => logger)
          kitchen_destroy.run_command
          if kitchen_destroy.error?
            raise "Command Failed"
          end
        ensure
          logger.close
        end
      end
    end

    def self.create(task_name, location, cookbook, params = {})
      # params[:chef_version]
      # params[:kitchen_config]
      
      location = File.expand_path(location)

      # Create a copy of the cookbook
      FileUtils.mkdir_p(location)
      local_cookbook = cookbook.repository.clone_to(File.join(location, 'cookbook'))

      # Write out task specification
      task_spec = {
        '__type__'     => 'kitchen_instance',
        '__name__'     => task_name,
        'git_sha'      => local_cookbook.head,
        'chef_version' => params[:chef_version]
      }

      File.write(File.join(location, 'task.spec'), task_spec.to_yaml)

      kitchen_task = KitchenInstanceTask.new(task_name, location, task_spec)

      # Write out kitchen.yml
      driver_config = {
        'name' => 'ec2',
        'instance_type' => 'm3.medium',
      }

      platform_name = params[:kitchen_config]['platform']['name']
      unless PLATFORM_NAMES.include?(platform_name)
        raise Braindump::InvalidInstance.new("Could not handle platform of type #{platform_name}")
      end

      suite_config = params[:kitchen_config]
      suite_config.delete('driver')

      suite_config['provisioner']['require_chef_omnibus'] = params[:chef_version]
      
      kitchen_config = {
        'platforms' => PLATFORMS,
        'driver' => driver_config,
        'suites' => [suite_config],
      }

      File.write(kitchen_task.kitchen_yaml, kitchen_config.to_yaml)

      kitchen_task
    end

    def environment
      { 'KITCHEN_YAML' =>  kitchen_yaml }
    end

    def kitchen_yaml
      File.join(location, 'cookbook', '.kitchen.braindump.yml')
    end

  end
end
