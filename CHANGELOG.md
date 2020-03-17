# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/chris-allen/dream-ops/compare/v0.5.0...HEAD
[0.4.2]: https://github.com/chris-allen/dream-ops/compare/v0.4.2...v0.5.0
[0.4.2]: https://github.com/chris-allen/dream-ops/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/chris-allen/dream-ops/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/chris-allen/dream-ops/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/chris-allen/dream-ops/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/chris-allen/dream-ops/compare/v0.1.0...v0.2.0