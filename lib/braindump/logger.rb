require 'mixlib/log'

module Braindump
  class Logger
    extend Mixlib::Log
    Logger.level = :warn
  end
end
