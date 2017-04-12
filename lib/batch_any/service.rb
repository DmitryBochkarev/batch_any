module BatchAny
  class Service
    attr_reader :item_class, :items

    def initialize(item)
      @item_class = item.class
      @items = [item]
    end

    def can_serve?(item)
      raise "Not implemented: #{self.class}#can_serve?(item) -> truthy, required by BatchAny::Service"
    end

    def fetch
      raise "Not implemented: #{self.class}#fetch, required by BatchAny::Service"
    end
  end
end
