# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- `stats` command: Added new option switch `-H`/`--human`.
- `stats` command: Added new option switch `--reverse` to reverse the sort
  order.

### Changed

- **BREAKING:** Message sizes are now output in bytes by default. This also
  applies to CSV output. Use the new `-H`/`--human` switch to convert byte
  counts to SI-prefixed numbers.
- **BREAKING:** The sort properties `q1` and `q3` have been renamed to `q1_size`
  and `q3_size`.
- Output: Draw table borders in blue for better visual separation.
- Output: Draw a separator line above the 'total' row.
- Updated dependencies.

### Fixed

- `stats` command: Sort did not work at all.
- Do not crash when collecting stats for mailboxes with a very large number of
  messages. Closes Github issue #8.

### Removed

- **BREAKING:** Removed the `-O` switch to reverse the sort order as it did not
  work as intended

## v1.0.7 (2022-03-02)

### Changed

- Update dependencies.

## v1.0.6

### Fixed

- Fix Docker build.

## v1.0.5

### Fixed

- Update bundle to address CVE-2018-1000201.

## v1.0.4

### Fixed

- Update rake to address CVE-2020-8130.

## Previous versions

#### Fixed

- Fix: Docker image.
- Fix: Options error message.
