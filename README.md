# Lapidary

Don't write your code, *and* rbs types! Write the rbs types first, then generate a template to
fill in with business logic.

## Usage

```sh
$ lap sig/file.rbs # outputs to stdout
$ lap sig/file.rbs > lib/file.rb # output into a file
```

## Example

0. Plan your project/module/class by writing some blueprints:
```ruby
# sig/lib/bank/account.rbs
module Bank
  class Account
    attr_reader interest_rate: Float
    attr_reader owner: Bank::Customer
    attr_reader balance: Float
    
    type date_or_dt = Date | DateTime
    
    # can optionally specify when the transaction should take place
    def deposit: (Float amount, ?when: date_or_dt) -> Float
    
    # can optionally specify when the transaction should take place
    def withdraw: (Float amount, ?when: date_or_dt) -> Float
    
    # must filter results by specifying `to` and `from` params
    def transactions: (from: date_or_dt, to: date_or_dt) -> Array[Bank::Transaction]
  end
end
```

1. Generate your ruby templates

```sh
$ lap sig/lib/bank/account.rbs > lib/bank/account.rb
```

(Generates lib/bank/account.rb)
```ruby
module Bank
  class Account
    attr_reader :interest_rate
    attr_reader :owner
    attr_reader :balance
    
    def initialize(owner, interest_rate, balance)
        @owner = owner
        @interest_rate = interest_rate
        @balance = balance
    end

    # can optionally specify when the transaction should take place
    def deposit(amount, when: nil)
      # TODO: return Float
    end

    # can optionally specify when the transaction should take place
    def withdraw(amount, when: nil)
      # TODO: return Float
    end

    # must filter results by specifying `to` and `from` params
    def transactions(to:, from:)
      # TODO: return Array
    end
  end
end
```

2. Fill in your business logic!

```ruby
module Bank
  class Account
    attr_reader :interest_rate
    attr_reader :owner
    attr_reader :balance
    
    def initialize(owner, interest_rate, balance)
        @owner = owner
        @interest_rate = interest_rate
        @balance = balance
    end

    # can optionally specify when the transaction should take place
    def deposit(amount, when: nil)
      @balance += amount
    end

    # can optionally specify when the transaction should take place
    def withdraw(amount, when: nil)
      @balance -= amount
    end

    # must filter results by specifying `to` and `from` params
    def transactions(to:, from:)
      Transaction.where("created_at BETWEEN ? AND ?", from, to)
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cutter'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cutter

## Coverage

Currently not every feature of RBS is supported - yet! (contributions
welcome!)

Feature|Coverage
---|---
classes (includes nested)|✅
modules (includes nested)|✅
class methods|✅
instance methods|✅
required positional arguments|✅
optional positional arguments|✅
required keyword arguments|✅
optional keyword arguments|✅
method comments|✅
access modifiers|⚠️
methods with blocks|⚠️
method overloading|⚠️
attr_reader|⚠️
attr_writer|⚠️
attr_accessor|⚠️
include|⚠️
extend|⚠️
procs|⚠️
constants|⚠️
interfaces|⚠️


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/johansenja/lapidary.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
