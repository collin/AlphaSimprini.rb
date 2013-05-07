class AlphaSimprini::RunLoop
  class Queue
    include AlphaSimprini::Logger

    def initialize(name)
      @name = name
      @tasks = []
    end

    def drain
      return unless @tasks.any?
      profile "Draining #{@name} (#{@tasks.count} tasks)" do      
        while task = @tasks.shift
          task.call 
        end
      end
    end

    def enqueue(&block)
      @tasks << block
    end
  end

  def self.enqueue(queue_name, &block)
    send(queue_name).enqueue(&block)
  end

  def self.drain
    queues.map(&:drain)
    return true
  end

  def self.queues
    [sync, render, after_render]
  end

    class << self
    attr_accessor :sync, :render, :after_render
  end

  self.sync = Queue.new(:sync)
  self.render = Queue.new(:render)
  self.after_render = Queue.new(:after_render)
end