# BatchAny

Allows you to use the batching service both for grouping requests into one and a single access to api. It makes it easy to integrate the batching service into the current logic without huge refactoring.
Internally it uses [Fibers](http://ruby-doc.org/core-2.4.1/Fiber.html) to pause current control flow and resumes after batches are formed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'batch_any'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install batch_any

## Usage

```ruby
STORAGE = [:a, :b].freeze

class Service < BatchAny::Service
  @@fetch_count = 0

  def self.fetch_count
    @@fetch_count
  end

  def can_serve?(item)
    item.class == Request
  end

  def fetch
    @@fetch_count += 1
    items.each { |item| item.value = STORAGE.fetch(item.index) }
  end
end

class Request < BatchAny::Item
  attr_reader :index

  def initialize(index)
    @index = index
  end

  def service_class
    Service
  end
end

a = nil
b = nil

batching_manager = BatchAny::Manager.new
batching_manager.add_computation { a = Request.new(0).fetch }
batching_manager.add_computation { b = Request.new(1).fetch }
batching_manager.run

puts a
# => a
puts b
# => b
puts Service.fetch_count
# => 1 # not 2
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DmitryBochkarev/batch_any.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
