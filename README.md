# DreamOps
[![Gem Version](https://img.shields.io/gem/v/dream-ops.svg)][gem]
[![Build Status](https://travis-ci.org/chris-allen/dream-ops.svg?branch=master)](https://travis-ci.org/chris-allen/dream-ops)

[gem]: https://rubygems.org/gems/dream-ops

CLI for Dream projects based on the [berkshelf](https://github.com/berkshelf/berkshelf) project.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dream-ops'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dream-ops

## Usage

```bash
dream help
```

### Deploying to OpsWorks

```bash
dream deploy opsworks --stacks 08137c03-1e85-4787-b82c-cb825638cdfa
Stack: nodeapp
--- Cookbook: chef-nodeapp
--- Apps: ["nodeapp"]
...Building cookbook [chef-nodeapp]
...Deploying cookbook [chef-nodeapp]
...Updating custom cookbooks [stack="nodeapp"]
...Running setup command [stack="nodeapp"]
...Deploying [stack="nodeapp"] [app="nodeapp"]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dream-ops.