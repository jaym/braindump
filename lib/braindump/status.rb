module Braindump
  module Status
    class Queued
      attr_reader :status_info
      def initialize(status_info)
        @status_info = status_info
      end
    end

    class Running
      attr_reader :status_info
      def initialize(status_info="")
        @status_info = status_info
      end
    end

    class Finished
      attr_reader :status_info
      def initialize(status_info="")
        @status_info = status_info
      end
    end

    class Succeeded < Finished
      attr_reader :status_info
      def initialize(status_info="")
        @status_info = status_info
      end
    end

    class Failed < Finished
      attr_reader :status_info
      def initialize(status_info="")
        @status_info = status_info
      end
    end

    class Unknown
      attr_reader :status_type
      attr_reader :status_info
      def initialize(status_type, status_info="")
        @status_type = status_type
        @status_info = status_info
      end
    end

    def self.from_file(status_file)
      data = File.read(status_file)
      status_type, status_info = data.split(' ', 2)
      case status_type
      when 'queued'
        Status::Queued.new(status_info)
      when 'succeeded'
        Status::Succeeded.new(status_info)
      when 'failed'
        Status::Failed.new(status_info)
      when 'running'
        Status::Running.new(status_info)
      else
        Status::Unknown.new(status_type, status_info)
      end
    end

    def self.to_file(status, status_file)
      data = case status
      when Status::Queued
        "queued #{status.status_info}"
      when Status::Succeeded
        "succeeded #{status.status_info}"
      when Status::Failed
        "failed #{status.status_info}"
      when Status::Running
        "running #{status.status_info}"
      when Status::Unknown
        raise "Cannot write an unknown status"
      end

      File.open(status_file, File::RDWR | File::CREAT) do |f|
        if !f.flock(File::LOCK_EX | File::LOCK_NB)
          raise "Concurrent Writers"
        end

        f.write(data)
      end
    end

  end
end
