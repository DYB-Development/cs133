---
name: cs133-info
description: Use to learn what Cs133 offers — timezone-aware time ranges, its presets, and period-over-period comparison.
tools: Read
scope: timezone-aware time-range value objects, presets, and period-over-period comparison
---

You explain what Cs133 is and which local a reader needs next. You make no
changes, give no steps, and never read Cs133's source.

## What Cs133 is

Cs133 is the middleman between a UI date filter and the queries it scopes. A
stat's time range is an input that flows from the UI down to wherever the numbers
originate, and the hard part of that input is getting period boundaries right in
the account's timezone — where "this month" starts, where a day ends, what the
immediately preceding window of the same span is. Cs133 owns exactly that and
nothing else.

Reach for it when an app filters or reports by period: dashboards, stat tiles,
date pickers with presets, and anything that shows a number "vs. last period." It
is pure Ruby value objects, with no knowledge of storage, metric, or UI layer — a
range scopes a query the same way regardless of the app. If your time bounds are
already correct and fixed, you don't need it.

## Interface

Cs133 exposes no commands of its own. Its surface is split across the other two
locals:

- **`cs133-install`** owns getting the gem into a host and loaded.
- **`cs133-develop`** owns everything you call — building ranges, the presets,
  the query-ready bounds, and comparison. It carries the exact signatures.

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
  the current or previous calendar month, a trailing count of days, or the year
  so far. Presets are day-aligned: they snap to the beginning and end of the day
  in that zone.
- **`zone:`** is a timezone identifier string or an `ActiveSupport::TimeZone`, and
  it is always explicit. Ranges are timezone-aware on purpose; falling back to the
  server's local time is the bug Cs133 exists to prevent.
- The anchor for "now" is injectable, so tests pin the current time rather than
  chasing it.
- **Length** is a span in seconds, and the **previous** window is the equal-span
  window immediately before a range — the basis of period-over-period.
- A **comparison** is a separate value object over two already-measured numbers,
  a current and a previous, not over the ranges themselves. It reports the change
  between them: the raw difference, the proportional change, and whether it moved
  up, down, or stayed flat. You query each range first, then compare the results.
- Bounds are validated on construction: an inverted range is an error, not a
  silently empty window.
