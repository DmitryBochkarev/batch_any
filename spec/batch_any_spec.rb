require 'spec_helper'

RSpec.describe BatchAny do
  STORAGE = [:a, :b].freeze

  class Service < described_class::Service
    @@fetch_count = 0

    def self.fetch_count
      @@fetch_count
    end

    def self.reset
      @@fetch_count = 0
    end

    def can_serve?(item)
      item.class == Request
    end

    def fetch
      @@fetch_count += 1
      items.each { |item| item.value = STORAGE.fetch(item.index) }
    end
  end

  class Request < described_class::Item
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def service_class
      Service
    end
  end

  before { Service.reset }

  it 'fetch items not in context of batch manager' do
    expect(Request.new(0).fetch).to eq :a
    expect(Request.new(1).fetch).to eq :b
    expect(Service.fetch_count).to eq 2
  end

  it 'fetch items in context of batch manager' do
    m = described_class::Manager.new
    m.add_computation { expect(Request.new(0).fetch).to eq :a }
    m.add_computation { expect(Request.new(1).fetch).to eq :b }
    m.run
    expect(Service.fetch_count).to eq 1
  end
end
