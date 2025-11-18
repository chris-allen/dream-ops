# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0]

### Changed
- Updated minimum Ruby version requirement from 2.3.1 to 3.4.0
- Updated `berkshelf` from ~> 7.0 to ~> 8.1
- Updated `chef` from ~> 13.6 to ~> 18.8

### Added
- Added `.ruby-version` file to specify Ruby 3.4.0

## [0.8.1]

### Fixed
- Resolved issue with `archive-tar-minitar`

### Changed
- Now tracking `Gemfile.lock` in version control
- Switched from travis-ci to github actions

## [0.8.0]

### Changed
- Updated to use CINC instead of Chef Workstation
- Updated to `thor@1.x` which removes warnings when using ruby 3.x

### Fixes
- Adds `solo` support for Ubuntu 22.04
- Better error handling of missing SSH key for `solo` commands

## [0.7.0]

### Changed
- Updated to use Chef Workstation instead of ChefDK

### Fixes
- Adds `solo` support for Ubuntu 20.04

## [0.6.1]

### Fixes
- Now using thread-safe enum to avoid `FiberError`

## [0.6.0]

### Added
- Added global `aws_profile` option
- Added spinner to all deployments to avoid CI hangs

## [0.5.0]

### Changed
- **BREAKING CHANGE**: Removed syncing of code for `solo` deployments

## [0.4.2]

### Changed
- SSH options now set `LogLevel=ERROR`

## [0.4.1]

### Changed
- Silences stderr for _all_ ssh commands

## [0.4.0]

### Changed
- **BREAKING CHANGE**: Renamed `-s` and `--stacks` options to `-T` and `--targets` respectively
- Updated to `"berkshelf" ~> 7.0`
- Updated to `"chef" ~> 13.6`
- Updated to `"thor" ~> 0.20`

### Added
- Added `solo` deploy type
- New `init` command for initializing configuration
- Added global `ssh_key` option
- Added global `force_setup` option
- Better error handling / logging

### Removed
- Removed `ridley` as a dependency

## [0.3.0]

### Fixes
- Problem with newer S3 domains

### Added
- Travis CI integration along with sample unit test

## [0.2.0]

### Added
- Better error handling / logging
- Gem version badge to README
- Usage documentation

[Unreleased]: https://github.com/chris-allen/dream-ops/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/chris-allen/dream-ops/compare/v0.8.1...v0.9.0
[0.8.1]: https://github.com/chris-allen/dream-ops/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/chris-allen/dream-ops/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/chris-allen/dream-ops/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/chris-allen/dream-ops/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/chris-allen/dream-ops/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/chris-allen/dream-ops/compare/v0.4.2...v0.5.0
[0.4.2]: https://github.com/chris-allen/dream-ops/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/chris-allen/dream-ops/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/chris-allen/dream-ops/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/chris-allen/dream-ops/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/chris-allen/dream-ops/compare/v0.1.0...v0.2.0