# DreamOps
[![Gem Version](https://img.shields.io/gem/v/dream-ops.svg)][gem]
![Build Status](https://github.com/chris-allen/dream-ops/actions/workflows/ci.yml/badge.svg)

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
Commands:
  dream deploy [TYPE] -T, --targets=one two three  # Deploys to specified targets
  dream help [COMMAND]                             # Describe available commands or one specific command
  dream init [TYPE] -T, --targets=one two three    # Initialize configuration on specified targets
  dream version                                    # Display version

Options:
  -F, [--format=FORMAT]            # Output format to use.
                                   # Default: human
  -q, [--quiet], [--no-quiet]      # Silence all informational output.
  -d, [--debug], [--no-debug]      # Output debug information
  -i, [--ssh-key=SSH_KEY]          # Path to SSH key
  -p, [--aws-profile=AWS_PROFILE]  # AWS profile to use

```

### Deploying to OpsWorks

```bash
dream deploy opsworks -T 08137c03-1e85-4787-b82c-cb825638cdfa
Stack: nodeapp
--- Cookbook: chef-nodeapp
--- Apps: ["nodeapp"]
...Building cookbook [chef-nodeapp]
...Deploying cookbook [chef-nodeapp]
...Updating custom cookbooks [stack="nodeapp"]
...Running setup command [stack="nodeapp"]
...Deploying [stack="nodeapp"] [app="nodeapp"]
```

### Deploy Using `chef-solo`

```bash
dream deploy solo -T ubuntu@example.com -i /path/to/key.pem
Target: ip-172-31-53-232
--- Cookbook: chef-nodeapp (outdated)
...Building cookbook [chef-nodeapp]
...Deploying cookbook [chef-nodeapp]
...Syncing [repo="nodeapp" target="ubuntu@example.com"]
...Running setup role [target="ubuntu@example.com"]
...Running deploy role [target="ubuntu@example.com"]
```

### Initialize `chef-solo`

```bash
dream init solo -T ubuntu@example.com -i /path/to/key.pem
Target: ip-172-31-53-232
--- Is chef-solo Installed: false
--- Valid chef.json: false
--- Valid role[setup]: false
--- Valid role[deploy]: false
...Installing chef-solo via CINC [target="ubuntu@example.com"]
...Creating boilerplate /var/chef/chef.json [target="ubuntu@example.com"]
...Creating boilerplate /var/chef/roles/setup.json [target="ubuntu@example.com"]
...Creating boilerplate /var/chef/roles/deploy.json [target="ubuntu@example.com"]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.


## Release
### switch to `main` branch:
- Change package version in `version.rb` according to release changes (`major|minor|patch`).
- Update `CHANGELOG.md`:
  - Rename `[Unreleased]` section to reflect new release version and release date, same format as for all previous releases
  - Create new `[Unreleased]` section on top of file, as it was previously
  - On the bottom of `CHANGELOG.md` file, create comparison reference for current release changes:
```
# was
[Unreleased]: https://github.com/chris-allen/dream-ops/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/chris-allen/dream-ops/compare/v0.2.0...v0.3.0

# became
# - "Unreleased" renamed to commit version
# - new "Unreleased" created, comparing last "0.4.0" commit with "HEAD"
[Unreleased]: https://github.com/chris-allen/dream-ops/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/chris-allen/dream-ops/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/chris-allen/dream-ops/compare/v0.2.0...v0.3.0
```
  - Commit `CHANGELOG.md` and `version.rb` with message `:rocket: {version}` (where version is your release version)

- Then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chris-allen/dream-ops.