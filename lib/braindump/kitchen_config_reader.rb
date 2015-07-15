require 'kitchen'

module Braindump
  class KitchenConfigReader
    attr_reader :kitchen_yaml
    attr_reader :loader
    attr_reader :data

    def initialize(kitchen_yaml)
      @kitchen_yaml = kitchen_yaml
      @loader = Kitchen::Loader::YAML.new(:project_config => kitchen_yaml)
      @data = Kitchen::DataMunger.new(loader.read, kitchen_config)
    end

    def instances
      @instances ||= rekey(build_instances)
    end

    def platform_names
      @platform_names ||= platforms.map {|p| p.name}
    end

    private

    def rekey(val)
      if val.is_a?(Hash)
        val.inject({}) do |memo, (k,v)|
          memo[k.to_s] = rekey(v)
          memo
        end
      elsif val.is_a?(Array)
        val.map {|v| rekey(v)}
      else
        val
      end
    end

    def build_instances
      filter_instances.map.with_index do |(suite, platform), index|
        suite_for(suite, platform)
      end
    end

    def filter_instances
      suites.product(platforms).select do |suite, platform|
        if !suite.includes.empty?
          suite.includes.include?(platform.name)
        elsif !suite.excludes.empty?
          !suite.excludes.include?(platform.name)
        else
          true
        end
      end
    end

    # @return [Collection<Platform>] all defined platforms which will be used
    #   in convergence integration
    def platforms
      @platforms ||= Kitchen::Collection.new(
        data.platform_data.map { |pdata| Kitchen::Platform.new(pdata) })
    end

    # @return [Collection<Suite>] all defined suites which will be used in
    #   convergence integration
    def suites
      @suites ||= Kitchen::Collection.new(
        data.suite_data.map { |sdata| Kitchen::Suite.new(sdata) })
    end

    def kitchen_config
      {
        :defaults => {
          :driver => Kitchen::Driver::DEFAULT_PLUGIN,
          :provisioner => Kitchen::Provisioner::DEFAULT_PLUGIN
        }
      }
    end

    def driver_for(suite, platform)
      data.driver_data_for(suite.name, platform.name)
    end

    def platform_for(platform)
      {
        :name => platform.name,
        :os_type => platform.os_type,
        :shell_type => platform.shell_type
      }
    end

    def provisioner_for(suite, platform)
      data.provisioner_data_for(suite.name, platform.name)
    end

    def verifier_for(suite, platform)
      data.verifier_data_for(suite.name, platform.name)
    end

    def suite_for(suite, platform)
      {
        :name => Kitchen::Instance.name_for(suite, platform),
        :includes => [platform.name],
        :driver => driver_for(suite, platform),
        :platform => platform_for(platform),
        :provisioner => provisioner_for(suite, platform),
        :verifier => verifier_for(suite, platform)
      }
    end

  end
end
