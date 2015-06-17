# aka - The Missing Alias Manager

aka generate/edit/destroy/find permanent aliases with a single command.

aka requires ruby and is built for bash and zsh users.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aka'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aka

## Usage

    $ aka generate hello="echo helloworld"
    $ aka destroy hello
    $ aka edit hello
    $ aka find hello
    $ aka usage
    $ aka

## Requirement

Ruby

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ryangoh/aka.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
