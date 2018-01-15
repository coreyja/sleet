# frozen_string_literal: true

module Sleet
  class Fetcher
    def initialize(source_dir:, input_filename:, output_filename:)
      @source_dir = source_dir
      @input_filename = input_filename
      @output_filename = output_filename
    end

    private

    attr_reader :source_dir, :input_filename, :output_filename
  end
end
