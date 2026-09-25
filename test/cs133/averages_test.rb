# frozen_string_literal: true

require "test_helper"

module Cs133
  class AveragesTest < Minitest::Test
    def test_a_month_averages_four_and_a_third_weeks
      assert_in_delta 4.33, Averages::WEEKS_IN_A_MONTH
    end
  end
end
