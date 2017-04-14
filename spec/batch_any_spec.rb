require 'spec_helper'

RSpec.describe BatchAny do
  STORAGE = [:a, :b, :c, :d].freeze

  class Service < described_class::Service
    @@fetch_count = 0

    def self.fetch_count
      @@fetch_count
    end

    def self.reset
      @@fetch_count = 0
    end

    def can_serve?(item)
      items.first.index.to_i.odd? == item.index.to_i.odd?
    end

    def fetch
      @@fetch_count += 1
      items.each do |item|
        index = Integer(item.index)
        item.result { STORAGE.fetch(index) }
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
    expect(Request.new(2).fetch).to eq :c
    expect(Service.fetch_count).to eq 3
  end

  it 'fetch items in context of batch manager' do
    a = nil
    b = nil
    c = nil
    m = described_class::Manager.new
    m.add_computation { a = Request.new(0).fetch }
    m.add_computation { b = Request.new(1).fetch }
    m.add_computation { c = Request.new(2).fetch }
    m.run
    expect(a).to eq :a
    expect(b).to eq :b
    expect(c).to eq :c
    expect(Service.fetch_count).to eq 2
  end

  it 'item fetch failed' do
    expect { Request.new(100).fetch }.to raise_error(IndexError)
  end

  it 'batch fetch failed' do
    expect { Request.new('not a number').fetch }.to raise_error(ArgumentError)
  end

  context 'item fetch failed in context of batch manager and item failure handled' do
    it do
      a = nil
      b = nil
      c = nil
      m = described_class::Manager.new
      m.add_computation { a = Request.new(0).fetch }
      m.add_computation do
        expect { Request.new(100).fetch }.to raise_error(IndexError)
      end
      m.add_computation { b = Request.new(1).fetch }
      m.add_computation { c = Request.new(2).fetch }
      expect { m.run }.not_to raise_error
      expect(a).to eq :a
      expect(b).to eq :b
      expect(c).to eq :c
      expect(Service.fetch_count).to eq 2
    end
  end

  context 'item fetch failed in context of batch manager and item failure not handled' do
    it do
      a = nil
      b = nil
      c = nil
      run = nil
      m = described_class::Manager.new
      m.add_computation { a = Request.new(0).fetch }
      m.add_computation do
        Request.new(100).fetch
      end
      m.add_computation { b = Request.new(1).fetch }
      m.add_computation { c = Request.new(2).fetch }
      expect { run = m.run }.not_to raise_error
      expect(a).to eq :a
      expect(b).to eq :b
      expect(c).to eq :c
      expect(run).to eq []
      expect(Service.fetch_count).to eq 2
    end
  end

  context 'batch fetch failed in context of batch manager and item failure not handled' do
    it do
      a = nil
      m = described_class::Manager.new
      m.add_computation { a = Request.new('not a number').fetch }
      expect { m.run }.to raise_error(ArgumentError)
      expect(a).to be_nil
      expect(Service.fetch_count).to eq 1
    end
  end
end
