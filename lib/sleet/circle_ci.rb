# frozen_string_literal: true

require 'singleton'

module Sleet
  class CircleCi
    def self.get(url, token)
      connection.get(url, 'circle-token' => token)
    end

    def self.connection
      Faraday.new do |b|
        b.use FaradayMiddleware::FollowRedirects
        b.adapter :net_http
      end
    end
  end
end
