# Changelog

All notable changes to this project are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-09-30

### Added
- `Cs133::Range.last_weeks` returns the given number of whole weeks, Monday to Sunday in the given time zone, ending with the current week.
- `Cs133::Averages` gives the average number of weeks in a month, the average number of days in a month and the number of hours in a week.

## [0.1.0] - 2026-09-21

### Added
- Initial gem scaffold: timezone-aware time-range value objects (`Cs133`), plain
  Ruby (depends only on `activesupport` for timezone-correct boundaries).
