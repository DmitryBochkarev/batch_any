module BatchAny
  class Item
    attr_accessor :value

    def service_class
      raise "Not implemented: #{self.class}#service_class -> Class, required by BatchAny::Item"
    end

    def fetch
      if Thread.current[:batch_any_manager]
        Thread.current[:batch_any_manager].enqueue_item(self)
      else
        service_class.new(self, nil).fetch
      end
      @value
    end
  end
end
