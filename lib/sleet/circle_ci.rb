# frozen_string_literal: true

require 'singleton'

module Sleet
  class CircleCi
    include Singleton

    def token
      @_token ||= File.read("#{Dir.home}/.circleci.token").strip
    end

    def get(*args, &block)
      connection.get(*args, &block)
    end

    def self.get(url)
      instance.get(url)
    end

    private

    def connection
      @_connection ||= Faraday.new.tap { |c| c.basic_auth(token, '') }
    end
  end
end
