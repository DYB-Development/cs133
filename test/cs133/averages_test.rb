# frozen_string_literal: true

require "test_helper"

module Cs133
  class AveragesTest < Minitest::Test
    def test_a_month_averages_four_and_a_third_weeks
      assert_in_delta 4.33, Averages::WEEKS_IN_A_MONTH
    end

    def test_a_month_averages_a_little_over_thirty_days
      assert_in_delta 30.44, Averages::DAYS_IN_A_MONTH
    end

    def test_a_week_holds_one_hundred_and_sixty_eight_hours
      assert_equal 168, Averages::HOURS_IN_A_WEEK
    end
  end
end
