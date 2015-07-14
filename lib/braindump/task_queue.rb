module Braindump
  class TaskQueue
    attr_reader :directory, :id_file

    def initialize(dir)
      @directory = File.expand_path(dir)
      @id_file = File.join(@directory, 'id')
    end

    def queue(job_spec)
      id = next_id
      File.symlink(File.expand_path(job_spec), File.join(directory, id))
      id
    end

    def dequeue
      File.open(id_file, File::RDWR | File::CREAT) do |lock|
        lock.flock(File::LOCK_EX)

        jobs = Dir.entries(directory).reject do |f|
          ['.', '..', 'id'].include? f
        end.sort

        job = jobs.first

        if job
          job_link_path = File.join(directory, job)
          real_job_path = File.readlink(job_link_path)
          File.unlink(job_link_path)
          real_job_path
        else
          # Could reset counter here
          nil
        end
      end
    end

    def self.from_directory(dir)
      FileUtils.mkdir_p(File.expand_path(dir))
      TaskQueue.new(dir)
    end

    protected

    def next_id
      File.open(id_file, File::RDWR | File::CREAT) do |f|
        f.flock(File::LOCK_EX)
        value = f.read.to_i
        f.rewind
        f.write("%.15d" % (value + 1))
        f.flush
        "%.15d" % value
      end
    end
  end
end
