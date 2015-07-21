require 'braindump/omnitruck'

require 'mixlib/versioning'

module Braindump
  class BuildManager

    attr_reader :build_file

    def initialize(build_info_dir)
      @build_file = File.expand_path(File.join(build_info_dir, 'LATEST_BUILD'))
    end

    def update!
      current = latest_version
      latest = fetch_latest_version

      if current.nil? || latest > current
        File.open(build_file, File::RDWR | File::CREAT) do |f|
          f.flock(File::LOCK_EX)
          read_version = version(f.read)
          if read_version == current
            f.rewind
            f.write(latest.input)
            f.flush
          end
        end
      end

      latest_version
    end

    def latest_version
      value = nil
      File.open(build_file, File::RDWR | File::CREAT) do |f|
        f.flock(File::LOCK_SH)
        value = f.read
      end
      version(value)
    end

    private

    def fetch_latest_version
      Braindump::Omnitruck.new('chef').nightlies.first
    end

    def version(v)
      Mixlib::Versioning.parse(v, [
        Mixlib::Versioning::Format::GitDescribe, 
        Mixlib::Versioning::Format::OpscodeSemVer, 
        Mixlib::Versioning::Format::Rubygems,
        Mixlib::Versioning::Format::SemVer, 
      ])
    end

  end
end
