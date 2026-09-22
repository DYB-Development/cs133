# frozen_string_literal: true

require "test_helper"

module Cs133
  class RangeTest < Minitest::Test
    def test_between_spans_the_selected_dates_from_day_start_to_day_end_in_zone
      zone = "America/Los_Angeles"
      tz = ActiveSupport::TimeZone[zone]
      range = Range.between(start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 30), zone: zone)

      assert_equal tz.local(2026, 6, 1)..tz.local(2026, 6, 30).end_of_day, range.to_range
    end

    def test_between_covers_the_whole_single_day_when_start_equals_end
      zone = "America/Los_Angeles"
      tz = ActiveSupport::TimeZone[zone]
      day = Date.new(2026, 6, 15)
      range = Range.between(start_date: day, end_date: day, zone: zone)

      assert_equal tz.local(2026, 6, 15)..tz.local(2026, 6, 15).end_of_day, range.to_range
    end

    def test_between_rejects_a_start_date_after_the_end_date
      assert_raises(Cs133::Range::InvalidBoundsError) do
        Range.between(start_date: Date.new(2026, 6, 30), end_date: Date.new(2026, 6, 1), zone: "America/Los_Angeles")
      end
    end

    def test_exposes_start_time
      start_time = Time.utc(2026, 6, 1)
      range = Range.new(start_time: start_time, end_time: Time.utc(2026, 6, 30))

      assert_equal start_time, range.start_time
    end

    def test_exposes_end_time
      end_time = Time.utc(2026, 6, 30)
      range = Range.new(start_time: Time.utc(2026, 6, 1), end_time: end_time)

      assert_equal end_time, range.end_time
    end

    def test_to_range_spans_start_through_end
      start_time = Time.utc(2026, 6, 1)
      end_time = Time.utc(2026, 6, 30)
      range = Range.new(start_time: start_time, end_time: end_time)

      assert_equal start_time..end_time, range.to_range
    end

    def test_length_is_the_duration_in_seconds
      range = Range.new(start_time: Time.utc(2026, 6, 1), end_time: Time.utc(2026, 6, 1, 1))

      assert_equal 3600, range.length
    end

    def test_this_month_spans_the_calendar_month_in_zone
      zone = "America/Los_Angeles"
      tz = ActiveSupport::TimeZone[zone]
      range = Range.this_month(zone: zone, now: Time.utc(2026, 6, 15, 12))

      assert_equal tz.local(2026, 6, 1)..tz.local(2026, 6, 30).end_of_day, range.to_range
    end

    # 2026-07-01 03:00 UTC is still 2026-06-30 in Los Angeles, so "last month" is May.
    def test_last_month_uses_the_previous_calendar_month_in_zone
      zone = "America/Los_Angeles"
      tz = ActiveSupport::TimeZone[zone]
      range = Range.last_month(zone: zone, now: Time.utc(2026, 7, 1, 3))

      assert_equal tz.local(2026, 5, 1)..tz.local(2026, 5, 31).end_of_day, range.to_range
    end

    # 2026-06-15 03:00 UTC is still 2026-06-14 in Los Angeles, so the 7-day
    # window (inclusive, day-aligned) is Jun 8 through Jun 14.
    def test_last_7_days_covers_seven_day_aligned_days_ending_today_in_zone
      zone = "America/Los_Angeles"
      tz = ActiveSupport::TimeZone[zone]
      range = Range.last_7_days(zone: zone, now: Time.utc(2026, 6, 15, 3))

      assert_equal tz.local(2026, 6, 8)..tz.local(2026, 6, 14).end_of_day, range.to_range
    end

    def test_last_30_days_covers_thirty_day_aligned_days_ending_today_in_zone
      zone = "America/Los_Angeles"
      tz = ActiveSupport::TimeZone[zone]
      range = Range.last_30_days(zone: zone, now: Time.utc(2026, 6, 15, 3))

      assert_equal tz.local(2026, 5, 16)..tz.local(2026, 6, 14).end_of_day, range.to_range
    end

    # 2027-01-01 03:00 UTC is still 2026-12-31 in Los Angeles, so YTD is 2026.
    def test_year_to_date_runs_from_start_of_year_to_now_in_zone
      zone = "America/Los_Angeles"
      now = Time.utc(2027, 1, 1, 3)
      tz = ActiveSupport::TimeZone[zone]
      range = Range.year_to_date(zone: zone, now: now)

      assert_equal tz.local(2026, 1, 1)..now.in_time_zone(tz), range.to_range
    end

    def test_previous_ends_immediately_before_the_range_begins
      range = Range.year_to_date(zone: "America/Los_Angeles", now: Time.utc(2027, 1, 1, 3))

      assert_equal range.start_time, range.previous.end_time
    end

    def test_last_weeks_returns_the_number_of_weeks_asked_for
      weeks = Range.last_weeks(3, zone: "America/New_York", now: Time.utc(2026, 11, 12, 15))

      assert_equal 3, weeks.length
    end
  end
end
