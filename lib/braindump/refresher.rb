require 'braindump/cookbook_manager'
require 'braindump/build_manager'
require 'braindump/kitchen_config_reader'
require 'braindump/tasks/kitchen_instance'
require 'braindump/agent'
require 'braindump/logger'

module Braindump
  class Refresher

    def initialize(base_dir)
      @base_dir = base_dir
    end

    def run
      cookbook_manager = Braindump::CookbookManager.new(base_dir)
      build_manager = Braindump::BuildManager.new(base_dir)
      task_manager = Braindump::Agent.task_manager(base_dir)

      build_manager.update!
      build_version = build_manager.latest_version

      Logger.debug("Found Chef Version #{build_version}")

      queued_tasks = []

      cookbook_manager.list.each do |cookbook|
        cookbook.repository.update
        sha = cookbook.repository.head

        Logger.debug("Found #{cookbook} at #{sha}")

        instances(cookbook).each do |instance|
          name = task_name(cookbook, build_version, sha, instance)
          location = task_location(cookbook, build_version, sha, instance)
          begin
            Logger.debug("Creating #{name} at #{location}")
            task = Braindump::KitchenInstanceTask.create(name, location, cookbook,
                                                  git_sha: sha,
                                                  chef_version: build_version,
                                                  kitchen_config: instance)
            if task_manager.register(task)
              queued_tasks << task
            else
              Logger.warn("Could not register task #{task.name}")
            end
          rescue Braindump::InvalidInstance => e
            Logger.warn(e.to_s)
          end
        end
      end
      queued_tasks
    end

    private

    def instances(cookbook)
      kitchen_yml = cookbook.repository.kitchen_yml
      begin
        f = Tempfile.new('kitchen.yml')
        f.write(kitchen_yml)
        f.flush
        reader = Braindump::KitchenConfigReader.new(f.path)
        instances = reader.instances
      ensure
        f.unlink
      end
    end

    def task_name(cookbook, build_version, sha, instance)
      [build_version.to_s, "#{cookbook.org_name}##{cookbook.repo_name}", sha, instance['name']].join('##')
    end

    def task_location(cookbook, build_version, sha, instance)
      File.join(base_dir, "tasks", build_version.to_s,
                "#{cookbook.org_name}##{cookbook.repo_name}", sha, instance['name'])
    end

    def base_dir
      @base_dir
    end

  end
end
