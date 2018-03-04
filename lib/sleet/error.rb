# frozen_string_literal: true

module Sleet
  class Error < ::Thor::Error
    def message
      "ERROR: #{super}".red
    end
  end
end
