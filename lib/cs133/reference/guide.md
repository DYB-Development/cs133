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
Cs133::Range.this_month(zone:, now: Time.now)         # => Cs133::Range spanning the current calendar month, in zone
Cs133::Range.last_month(zone:, now: Time.now)         # => Cs133::Range spanning the previous calendar month, in zone
Cs133::Range.last_7_days(zone:, now: Time.now)        # => Cs133::Range, 7 day-aligned days ending today, in zone
Cs133::Range.last_30_days(zone:, now: Time.now)       # => Cs133::Range, 30 day-aligned days ending today, in zone
Cs133::Range.year_to_date(zone:, now: Time.now)       # => Cs133::Range from the start of the year to now, in zone
Cs133::Range.last_weeks(count, zone:, now: Time.now)  # => Array of count Cs133::Range, Monday-to-Sunday weeks in zone, oldest first, the last holding now
Cs133::Range.new(start_time:, end_time:)              # => Cs133::Range from explicit bounds

range.start_time                                      # => Time/ActiveSupport::TimeWithZone, inclusive start
range.end_time                                        # => Time/ActiveSupport::TimeWithZone, inclusive end
range.to_range                                        # => (start_time..end_time), drop straight into where(...)
range.length                                          # => Float seconds, end_time minus start_time
range.previous                                        # => Cs133::Range, the equal-span window immediately before

Cs133::Comparison.new(current:, previous:)            # => Cs133::Comparison; raises UnequalLengthError unless lengths match
comparison.current                                    # => Cs133::Range, the current window
comparison.previous                                   # => Cs133::Range, the prior window

Cs133::Comparison::UnequalLengthError                 # < Cs133::Error, raised when current.length != previous.length

Cs133::Averages::WEEKS_IN_A_MONTH                     # => 4.33, average weeks in a month, weekly amount to monthly and back
Cs133::Averages::DAYS_IN_A_MONTH                      # => 30.44, average days in a month, daily amount to monthly and back
Cs133::Averages::HOURS_IN_A_WEEK                      # => 168, hours in a week
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
- Do not use `previous` to walk a run of calendar periods. It steps back by the
  range's length in elapsed seconds, so across a daylight saving change it lands
  an hour out and stays out — stepping back from the week of 9 November 2026 in
  `America/New_York` gives 26 October at 01:00 where the calendar gives 00:00.
  Use `last_weeks`, which steps by the calendar.
- Reach for the presets (`this_month`, `last_month`, `last_7_days`,
  `last_30_days`, `year_to_date`) before constructing a `Range` by hand.
- `Cs133::Averages` holds fixed averages, not values derived from a real date
  range. Use them to turn a weekly or daily amount into a monthly one and back.
  When the answer depends on an actual month, measure a `Range` instead.
- `WEEKS_IN_A_MONTH` is 4.33 and `DAYS_IN_A_MONTH` is 30.44, kept as they are
  rather than worked out from one year length, so 4.33 times 7 is not 30.44.
