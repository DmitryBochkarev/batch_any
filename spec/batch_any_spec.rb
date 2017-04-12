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
      items.each do |item|
        item.result { STORAGE.fetch(item.index) }
      end
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
    a = nil
    b = nil
    m = described_class::Manager.new
    m.add_computation { a = Request.new(0).fetch }
    m.add_computation { b = Request.new(1).fetch }
    m.run
    expect(a).to eq :a
    expect(b).to eq :b
    expect(Service.fetch_count).to eq 1
  end

  it 'fetch failed' do
    expect { Request.new(3).fetch }.to raise_error(IndexError)
  end

  context 'fetch failed in context of batch manager and item failure handled' do
    it do
      a = nil
      b = nil
      m = described_class::Manager.new
      m.add_computation { a = Request.new(0).fetch }
      m.add_computation do
        expect { Request.new(3).fetch }.to raise_error(IndexError)
      end
      m.add_computation { b = Request.new(1).fetch }
      expect { m.run }.not_to raise_error
      expect(a).to eq :a
      expect(b).to eq :b
      expect(Service.fetch_count).to eq 1
    end
  end

  context 'fetch failed in context of batch manager and item failure not handled' do
    it do
      a = nil
      b = nil
      m = described_class::Manager.new
      m.add_computation { a = Request.new(0).fetch }
      m.add_computation do
        Request.new(3).fetch
      end
      m.add_computation { b = Request.new(1).fetch }
      expect { m.run }.to raise_error(IndexError)
      expect(a).to eq :a
      expect(b).to be_nil
      expect(Service.fetch_count).to eq 1
    end
  end
end
