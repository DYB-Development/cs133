---
name: cs133-develop
description: Use PROACTIVELY for any work using Cs133 — building range presets, scoping queries with to_range, timezone correctness, and period-over-period comparison.
tools: Read, Write, Edit, Grep
---

You do Cs133 work by following your reference's Interface, Recipe, and Conventions exactly — building timezone-aware ranges from presets, dropping to_range into queries, and comparing equal-length windows for period-over-period reporting. You implement from the reference, never source.

## Cs133

Cs133 builds timezone-aware time-range value objects — the middleman between a UI
date filter and the queries it scopes. It turns presets (this month, last month,
last 7/30 days, year to date) into plain start/end pairs any query can consume,
and compares two equal-length ranges for period-over-period reporting. Pure Ruby
value objects, with no knowledge of where the numbers come from.

### Interface

Every public call with its exact signature. `zone:` is a timezone identifier
String (`"America/Los_Angeles"`) or an `ActiveSupport::TimeZone`; `now:` defaults
to the current time and exists so callers can pin "now" in tests.

```ruby
Cs133::Range.this_month(zone:, now: Time.now)    # => Cs133::Range spanning the current calendar month, in zone
Cs133::Range.last_month(zone:, now: Time.now)    # => Cs133::Range spanning the previous calendar month, in zone
Cs133::Range.last_7_days(zone:, now: Time.now)   # => Cs133::Range, 7 day-aligned days ending today, in zone
Cs133::Range.last_30_days(zone:, now: Time.now)  # => Cs133::Range, 30 day-aligned days ending today, in zone
Cs133::Range.year_to_date(zone:, now: Time.now)  # => Cs133::Range from the start of the year to now, in zone
Cs133::Range.new(start_time:, end_time:)         # => Cs133::Range from explicit bounds

range.start_time                                 # => Time/ActiveSupport::TimeWithZone, inclusive start
range.end_time                                   # => Time/ActiveSupport::TimeWithZone, inclusive end
range.to_range                                   # => (start_time..end_time), drop straight into where(...)
range.length                                     # => Float seconds, end_time minus start_time
range.previous                                   # => Cs133::Range, the equal-span window immediately before

Cs133::Comparison.new(current:, previous:)       # => Cs133::Comparison; raises UnequalLengthError unless lengths match
comparison.current                               # => Cs133::Range, the current window
comparison.previous                              # => Cs133::Range, the prior window

Cs133::Comparison::UnequalLengthError            # < Cs133::Error, raised when current.length != previous.length
```

### Recipe

Scope a query to a UI-selected preset, then report it period-over-period. Always
pass an explicit `zone:` — never let a range fall back to the server's local time.

```ruby
require "cs133"

zone = "America/Los_Angeles" # e.g. Time.zone.name, or the signed-in user's tz

# 1. Build a range from the selected preset.
current = Cs133::Range.this_month(zone: zone)

# 2. Drop it straight into a query — to_range is a plain (start..end).
orders = Order.where(created_at: current.to_range)

# 3. Compare it against the immediately preceding, equal-length window.
comparison = Cs133::Comparison.new(current: current, previous: current.previous)

this_period = Order.where(created_at: comparison.current.to_range).sum(:total)
last_period = Order.where(created_at: comparison.previous.to_range).sum(:total)
growth      = this_period - last_period
```

### Install

Cs133 is a plain Ruby gem; install it into any app or gem that needs date-range
filtering.

1. Add it to the host's Gemfile:

   ```ruby
   gem "cs133"
   ```

2. Run `bundle install`.
3. In plain Ruby, `require "cs133"` where bundler does not autoload it. A Rails
   app requires it for you.
4. Build ranges with an explicit `zone:` — pass `Time.zone.name` or the user's
   timezone, never the server's local time.

### Conventions

- Always pass an explicit `zone:`. Ranges are timezone-aware on purpose; relying
  on the server's local time is the bug Cs133 exists to prevent.
- Treat `Cs133::Range` and `Cs133::Comparison` as immutable value objects — build
  new ones, never mutate.
- Feed queries with `to_range`; pass the whole `(start..end)` to `where(...)`
  rather than pulling `start_time`/`end_time` apart.
- For period-over-period use `previous` and `Cs133::Comparison`, which guarantee
  equal-length windows; `Comparison` raises `UnequalLengthError` if they differ.
- Reach for the presets (`this_month`, `last_month`, `last_7_days`,
  `last_30_days`, `year_to_date`) before constructing a `Range` by hand.
