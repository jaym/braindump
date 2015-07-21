module Braindump
  module Mixin
    module Forks

      def fork_exec(cmd)
        Logger.info("Running #{cmd}")
        pid = Process.fork
        if pid.nil? then
          ObjectSpace.each_object(File) do |f|
            begin
              f.close
            rescue => e
            end
          end
          Process.daemon
          exec(cmd)
        else
          Process.detach(pid)
        end
      end

    end
  end
end
