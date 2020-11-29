# Lapidary

Don't write your code, *and* rbs types! Write the rbs types first, then generate a template to
fill in with business logic.

## Example



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cutter'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cutter

## Usage

Output the b
```sh
$ lap sig/file.rbs # outputs to stdout
$ lap sig/file.rbs > lib/file.rb # output into a file
```

## Coverage

Currently not every feature of RBS is supported, but the aim is to increase it (contributions
welcome!)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/johansenja/lapidary.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
