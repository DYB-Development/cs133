# frozen_string_literal: true

module Cs133
  class Range
    class InvalidBoundsError < Error; end

    def self.between(start_date:, end_date:, zone:)
      raise InvalidBoundsError if start_date > end_date

      new(start_time: start_date.in_time_zone(zone).beginning_of_day,
          end_time: end_date.in_time_zone(zone).end_of_day)
    end

    def self.this_month(zone:, now: Time.now)
      anchor = now.in_time_zone(zone)
      new(start_time: anchor.beginning_of_month, end_time: anchor.end_of_month)
    end

    def self.last_month(zone:, now: Time.now)
      anchor = now.in_time_zone(zone).prev_month
      new(start_time: anchor.beginning_of_month, end_time: anchor.end_of_month)
    end

    def self.last_7_days(zone:, now: Time.now)
      last_n_days(7, zone: zone, now: now)
    end

    def self.last_30_days(zone:, now: Time.now)
      last_n_days(30, zone: zone, now: now)
    end

    def self.year_to_date(zone:, now: Time.now)
      anchor = now.in_time_zone(zone)
      new(start_time: anchor.beginning_of_year, end_time: anchor)
    end

    def self.last_weeks(count, zone:, now: Time.now)
      monday = now.in_time_zone(zone).to_date.beginning_of_week(:monday)

      (count - 1).downto(0).map do |weeks_back|
        start_date = monday - weeks_back.weeks
        between(start_date: start_date, end_date: start_date + 6, zone: zone)
      end
    end

    def self.last_n_days(count, zone:, now:)
      anchor = now.in_time_zone(zone)
      new(start_time: (anchor - (count - 1).days).beginning_of_day, end_time: anchor.end_of_day)
    end
    private_class_method :last_n_days

    attr_reader :start_time, :end_time

    def initialize(start_time:, end_time:)
      @start_time = start_time
      @end_time = end_time
    end

    def to_range
      start_time..end_time
    end

    def length
      end_time - start_time
    end

    def previous
      self.class.new(start_time: start_time - length, end_time: end_time - length)
    end
  end
end
