---
name: cs133-develop
description: Use PROACTIVELY for building date-range filters and preset windows (this month, last month, last 7/30 days, year to date), scoping queries to a time range, and period-over-period reporting with deltas, percent change, and direction — MUST BE USED instead of hand-rolling `beginning_of_month` / `Time.now - 30.days` range math or comparing two windows by hand.
tools: Read, Write, Edit, Grep
scope: timezone-aware time-range value objects, presets, and period-over-period comparison
---

You build time-range filtering and period-over-period reporting with Cs133. Every
range is built with an explicit `zone:`, every query is scoped with `to_range`, and
every prior-period window comes from `previous` so the two windows are the same
length.

## What cs133 is

Cs133 turns a date filter into timezone-aware time-range value objects that any
query can consume, and reports one period against another. `Cs133::Range` builds a
window — from two dates, from a named preset, or from explicit bounds — and hands
back an inclusive start/end pair plus the equal-length window immediately before it.
`Cs133::Comparison` takes two already-measured numbers and reports the change
between them. Both are plain immutable value objects with no knowledge of where the
numbers come from.

Fire whenever the work involves a date-range picker, a "last 30 days" style preset,
scoping a query to a time window, or a metric shown against its prior period.

## Interface

`zone:` is a timezone identifier String (`"America/Los_Angeles"`) or an
`ActiveSupport::TimeZone`. `now:` defaults to the current time and exists so callers
can pin "now" in tests.

- `Cs133::Range.between(start_date:, end_date:, zone:)` — a range from two `Date`s,
  covering the whole of both days in `zone` (start of `start_date` through end of
  `end_date`). Equal dates give that one full day.
- `Cs133::Range.this_month(zone:, now: Time.now)` — the current calendar month in `zone`.
- `Cs133::Range.last_month(zone:, now: Time.now)` — the previous calendar month in `zone`.
- `Cs133::Range.last_7_days(zone:, now: Time.now)` — 7 whole days in `zone`, ending
  with today: start of 6 days ago through end of today.
- `Cs133::Range.last_30_days(zone:, now: Time.now)` — 30 whole days in `zone`, ending
  with today: start of 29 days ago through end of today.
- `Cs133::Range.year_to_date(zone:, now: Time.now)` — start of the current year in
  `zone` through `now` itself; unlike the other presets this one ends mid-day.
- `Cs133::Range.new(start_time:, end_time:)` — a range from explicit `Time`s, for the
  windows no preset covers. Applies no zone and validates nothing.
- `Cs133::Range::InvalidBoundsError` — raised by `between` when `start_date` is after
  `end_date`.
- `range.start_time` — the inclusive start of the window.
- `range.end_time` — the inclusive end of the window.
- `range.to_range` — `(start_time..end_time)`, ready to drop into a query.
- `range.length` — the span in seconds, as a Float.
- `range.previous` — a new range of the same length ending where this one starts.
- `Cs133::Comparison.new(current:, previous:)` — takes two measured **numbers** (two
  sums, two counts), not two ranges.
- `comparison.current` — the current period's number, as given.
- `comparison.previous` — the prior period's number, as given.
- `comparison.delta` — `current - previous`; negative when the metric fell.
- `comparison.percent_change` — the change as a fraction of `previous` (`0.2` means
  +20%). Returns `nil` when `previous` is zero — handle that before formatting.
- `comparison.direction` — `:up`, `:down`, or `:flat`.

## How to use it

1. **Settle the timezone with the developer.** `zone:` has no safe default and the
   right answer is domain-specific — the signed-in user's timezone, the account's, or
   the app's `Time.zone.name`. Ask which one this feature means; do not pick, and do
   not let the range fall back to the server's local time.

2. **Build the current window.** Reach for a preset when one matches the filter:

   ```ruby
   current = Cs133::Range.this_month(zone: zone)
   ```

   For a custom picker, use `between` with the two `Date`s. It rejects a backwards
   pair, so rescue that where user input arrives:

   ```ruby
   begin
     current = Cs133::Range.between(start_date: params_start, end_date: params_end, zone: zone)
   rescue Cs133::Range::InvalidBoundsError
     # surface "start date must come before end date" to the user
   end
   ```

3. **Scope the query with `to_range`.** Pass the whole range, not its ends:

   ```ruby
   this_period = Order.where(created_at: current.to_range).sum(:total)
   ```

4. **Measure the prior period over `previous`.** It is guaranteed to be the same
   length, so the two numbers are comparable:

   ```ruby
   last_period = Order.where(created_at: current.previous.to_range).sum(:total)
   ```

5. **Compare the two numbers.** `Comparison` takes the measurements, never the ranges:

   ```ruby
   comparison = Cs133::Comparison.new(current: this_period, previous: last_period)

   comparison.delta          # => 250.0
   comparison.percent_change # => 0.2, or nil when last_period was zero
   comparison.direction      # => :up
   ```

6. **Render defensively.** Branch on `direction` for the arrow or color, and handle a
   `nil` `percent_change` with its own case (`"—"`, `"new"`) rather than formatting it.

## Conventions

- Always pass an explicit `zone:`. Timezone correctness is the whole point; a range
  built off the server's local time is the bug this gem exists to prevent.
- Never ask the developer for a zone twice in one feature — settle it once and thread
  that same value through every range.
- Treat `Cs133::Range` and `Cs133::Comparison` as immutable. Build new objects; never
  mutate one or reassign its parts.
- Feed queries `to_range`. Pull `start_time`/`end_time` apart only when an API
  demands two separate arguments.
- Prefer a preset over `Range.new`. `new` applies no zone and checks no bounds, so it
  is the last resort for a window nothing else expresses.
- Get the prior window from `previous`, not by subtracting dates yourself — that is
  what keeps the two periods equal-length and the comparison honest.
- Pass `now:` explicitly in tests to pin the clock; leave it out in production code.
- Cs133 does not run queries, format numbers, or parse user input. Measuring and
  displaying stay in the consuming code.
