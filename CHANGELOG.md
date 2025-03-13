# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Version 2.1.0 (2025-03-13)][v2.1.0]

### Added

- New command-line flag `-l`/`--limit` to limit the statistics output to
  a given number of mailboxes (folders).

## [Version 2.0.1 (2025-03-11)][v2.0.1]

### Fixed

- Do not crash with empty IMAP mailboxes.

## [Version 2.0.0 (2025-03-10)][v2.0.0]

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

## [Version 1.0.7 (2022-03-02)][v1.0.7]

### Changed

- Update dependencies.

## Version 1.0.6

### Fixed

- Fix Docker build.

## [Version 1.0.5][v1.0.5]

### Fixed

- Update bundle to address CVE-2018-1000201.

## Version 1.0.4

### Fixed

- Update rake to address CVE-2020-8130.

## Previous versions

### Fixed

- Fix: Docker image.
- Fix: Options error message.

[v2.1.0]: https://github.com/bovender/imapcli/releases/tag/v2.1.0
[v2.0.1]: https://github.com/bovender/imapcli/releases/tag/v2.0.1
[v2.0.0]: https://github.com/bovender/imapcli/releases/tag/v2.0.0
[v1.0.7]: https://github.com/bovender/imapcli/releases/tag/v1.0.7
[v1.0.5]: https://github.com/bovender/imapcli/releases/tag/v1.0.5
