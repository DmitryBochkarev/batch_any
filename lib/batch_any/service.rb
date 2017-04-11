module BatchAny
  class Service
    attr_reader :item_class

    def initialize(item, fiber)
      @item_class = item.class
      @awaiting = {fiber => item}
    end

    def can_serve?(item)
      raise "Not implemented: #{self.class}#can_serve?(item) -> truthy, required by BatchAny::Service"
    end

    def fetch
      raise "Not implemented: #{self.class}#fetch, required by BatchAny::Service"
    end

    def items
      @awaiting.values
    end

    def append(item, fiber)
      @awaiting[fiber] = item
    end
  end
end
