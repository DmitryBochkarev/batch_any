module BatchAny
  class Manager
    def initialize
      @computations = []
      @awaiting_services = {}
    end

    def add_computation(&block)
      fiber = Fiber.new do
        Thread.current[:batch_any_manager] = self
        block.call
      end
      @computations << fiber
    end

    def run
      while @computations.any?
        @computations.each(&:resume)
        linear_keep_if!(@computations, &:alive?)
        @awaiting_services.values.each { |service| service.each(&:fetch) }
        @awaiting_services.clear
      end
    end

    def enqueue_item(item)
      service_class = item.service_class
      @awaiting_services[service_class] ||= []
      awaiting_services = @awaiting_services[service_class]
      service = awaiting_services.find { |service| service.can_serve?(item) }
      if service
        service.items << item
      else
        awaiting_services << item.service_class.new(item)
      end
      Fiber.yield
    end

    private

    # https://bugs.ruby-lang.org/issues/10714
    # https://github.com/ruby/ruby/commit/5ec029d1ea52224a365a11987379c3e9de74b47a
    def linear_keep_if!(arr)
      i = 0
      j = 0
      while i < arr.length
        v = arr[i]
        if yield v
          arr[j] = v
          j += 1
        end
        i += 1
      end
      i != j ? arr : nil
    ensure
      if i != j
        arr[j, i-j] = []
      end
    end
  end
end
