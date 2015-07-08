require 'kitchen'

module Braindump
  class NoConversion < Exception 
  end

  class Converter
    attr_reader :kitchen_yaml
    attr_reader :loader
    attr_reader :data

    def initialize(kitchen_yaml)
      @kitchen_yaml = kitchen_yaml
      @loader = Kitchen::Loader::YAML.new(:project_config => kitchen_yaml)
      @data = Kitchen::DataMunger.new(loader.read, kitchen_config)
    end

    def convert
      rekey({
        :platforms => platforms.map {|p| {:name => p.name}},
        :suites => build_instances
      })
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
        begin
          suite_for(suite, platform)
        rescue NoConversion
          nil
        end
      end.reject(&:nil?)
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
      driver_data = data.driver_data_for(suite.name, platform.name)
      box = driver_data[:box]
      ami = [box, platform.name].map do |p|
        find_ami(p)
      end.reject(&:nil?)
      if ami.length > 0
        {
          :name => "ec2",
          :image => ami.first
        }
      else
        raise NoConversion
      end
    end

    def find_ami(p)
      boxes_to_ami = {
        "ubuntu-12.04" => "ami-f3635fc3",
        "ubuntu-14.04" => "ami-f15b5dc1",
        "ubuntu-15.04" => "ami-414c4c71"
      }
      boxes_to_ami[p]
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
        :name => suite.name,
        :includes => [platform.name],
        :driver => driver_for(suite, platform),
        :platform => platform_for(platform),
        :provisioner => provisioner_for(suite, platform),
        :verifier => verifier_for(suite, platform)
      }
    end

  end
end
