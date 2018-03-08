# frozen_string_literal: true

require 'singleton'

module Sleet
  class CircleCi
    def self.get(url, token)
      Faraday.get(url, 'circle-token' => token)
    end
  end
end
