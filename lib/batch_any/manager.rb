module BatchAny
  class Manager
    class FiberError
      attr_reader :fiber, :exception

      def initialize(fiber, exception)
        @fiber = fiber
        @exception = exception
      end
    end

    attr_reader :exceptions

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
      fiber
    end

    def run
      @exceptions = []
      while @computations.any?
        @computations.each do |computation|
          begin
            computation.resume
          rescue => e
            @exceptions << FiberError.new(computation, e)
          end
        end
        linear_keep_if!(@computations, &:alive?)
        @awaiting_services.values.each do |services|
          services.each do |service|
            begin
              service.fetch
            rescue => e
              service.items.each { |item| item.exception = e }
            end
          end
        end
        @awaiting_services.clear
      end
      @exceptions
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
