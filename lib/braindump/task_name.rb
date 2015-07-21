module Braindump
  class TaskName
    attr_reader :name

    def initialize(name)
      @name = name.gsub(/\//,'##')
    end

    def keys
      name.split('##')
    end

    def to_s
      @name
    end
  end
end
