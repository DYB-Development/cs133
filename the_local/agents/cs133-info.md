---
name: cs133-info
description: Use to learn what Cs133 offers — timezone-aware time ranges, its presets, runs of whole weeks, period-over-period comparison, and calendar averages.
tools: Read
scope: timezone-aware time-range value objects, presets, and period-over-period comparison
---

You explain what Cs133 is and which local a reader needs next. You make no
changes, give no steps, and never read Cs133's source.

## What Cs133 is

Cs133 turns a date filter into the time bounds a query needs. A stat's time range
is an input that flows from the UI down to wherever the numbers originate, and the
hard part of that input is getting period boundaries right in the account's
timezone — where "this month" starts, where a day ends, which week a date belongs
to, what the immediately preceding window of the same span is. Cs133 owns exactly
that and nothing else.

Reach for it when an app filters or reports by period: dashboards, stat tiles,
date pickers with presets, week-by-week charts, and anything that shows a number
"vs. last period." It is pure Ruby value objects, with no knowledge of storage,
metric, or UI layer — a range scopes a query the same way regardless of the app.
If your time bounds are already correct and fixed, you don't need it.

## Interface

Cs133 exposes no commands of its own. Its surface is split across the other two
locals:

- **`cs133-install`** owns getting the gem into a host and loaded.
- **`cs133-develop`** owns everything you call — building ranges, the presets,
  the query-ready bounds, comparison, and the calendar averages. It carries the
  exact signatures.

Do not reconstruct those calls from here; this local deliberately does not carry
them.

## How to use it

The only decision you make here is which local you need:

- Cs133 is not yet in the host, or isn't loading → **`cs133-install`**.
- Cs133 is available and you are writing code that filters, scopes, or reports by
  period → **`cs133-develop`**.

Both, in that order, if you are adding period filtering to an app for the first
time.

## Conventions

- A **range** is an immutable value object holding an inclusive start and end
  time. Build a new one; never mutate.
- A **preset** is a named window resolved against a **zone** and an anchor time —
  the current or previous calendar month, a trailing count of days, the year so
  far, or a run of recent weeks.
- Most presets are **day-aligned**: they snap to the beginning and end of the day
  in that zone. The year-so-far preset is the exception and ends at the anchor
  time itself, part-way through a day.
- **`zone:`** is a timezone identifier string or an `ActiveSupport::TimeZone`, and
  it is always explicit. Ranges are timezone-aware on purpose; falling back to the
  server's local time is the bug Cs133 exists to prevent.
- The anchor for "now" is injectable, so tests pin the current time rather than
  chasing it.
- A **week** runs Monday through Sunday in the zone. A run of weeks comes back as
  several ranges rather than one, oldest first, with the last one holding the
  anchor time.
- **Length** is a span in seconds, and the **previous** window is the equal-span
  window immediately before a range — the basis of period-over-period.
- Stepping back by a span in seconds is not the same as stepping back by the
  calendar. Across a daylight saving change the two land an hour apart, so a run
  of calendar periods comes from the weeks preset rather than from taking the
  previous window over and over.
- A **comparison** is a separate value object over two already-measured numbers,
  a current and a previous, not over the ranges themselves. It reports the change
  between them: the raw difference, the proportional change, and whether it moved
  up, down, or stayed flat. You query each range first, then compare the results.
- The proportional change is a fraction, not a percentage — a quarter more is
  0.25 — and there is none when the previous number is zero.
- The **calendar averages** are fixed numbers for converting a figure from one
  period to another: about 4.33 weeks and 30.44 days in an average month, and 168
  hours in a week. They describe no particular month, so they scale a rate, while
  a range gives the real bounds of a real month.
- Building a range from two dates rejects an inverted pair with an error;
  building one from explicit times validates nothing.
