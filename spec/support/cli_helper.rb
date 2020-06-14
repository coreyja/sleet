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
    exit_with_code(1).and(output(message.red + "\n").to_stderr)
  end

  def without_error
    output_nothing.to_stderr
  end

  RSpec::Matchers.define_negated_matcher(:output_nothing, :output)

  RSpec::Matchers.define :exit_with_code do |exp_code|
    supports_block_expectations

    actual = nil
    match do |block|
      begin
        block.call
      rescue SystemExit => e
        actual = e.status
      end
      actual && (actual == exp_code)
    end
    failure_message do |_block|
      "expected block to call exit(#{exp_code}) but exit" +
        (actual.nil? ? ' was not called' : "(#{actual}) was called")
    end
    failure_message_when_negated do |_block|
      "expected block not to call exit(#{exp_code})"
    end
    description do
      "expect block to call exit(#{exp_code})"
    end
  end
end
