# frozen_string_literal: true

require 'open3'

module CliHelper
  def cli_executable_path
    "#{__dir__}/../../exe/sleet"
  end

  def expect_command(cmd)
    expect { Sleet::Cli.start(cmd.split(' ')) }
  end

  def error_with(message)
    output(message.red + "\n").to_stderr
  end

  def without_error
    output('').to_stderr
  end

  RSpec::Matchers.define_negated_matcher(:output_nothing, :output)
end
