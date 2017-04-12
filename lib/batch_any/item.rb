module BatchAny
  class Item
    attr_reader :value, :exception

    def service_class
      raise "Not implemented: #{self.class}#service_class -> Class, required by BatchAny::Item"
    end

    def fetch
      batching_manager = Thread.current[:batch_any_manager]
      if batching_manager
        batching_manager.enqueue_item(self)
      else
        service_class.new(self).fetch
      end
      raise @exception if @exception
      @value
    end

    def result
      @value = yield
    rescue => e
      @exception = e
    end
  end
end
