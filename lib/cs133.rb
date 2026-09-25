# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/time"
require "active_support/core_ext/date"
require "active_support/core_ext/numeric/time"

require_relative "cs133/version"

module Cs133
  class Error < StandardError; end
end

require_relative "cs133/range"
require_relative "cs133/comparison"
require_relative "cs133/averages"
require_relative "cs133/reference"
