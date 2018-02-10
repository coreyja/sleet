# frozen_string_literal: true

require 'open3'

module CliHelper
  def cli_executable_path
    "#{__dir__}/../../exe/sleet"
  end

  def expect_command(cmd)
    expect { Open3.capture3("#{cli_executable_path} #{cmd}") }
  end

  RSpec::Matchers.define :run do
    supports_block_expectations

    match do |actual|
      return false unless actual.is_a? Proc
      begin
        stdout, stderr, status = actual.call
        status_matches?(status) && stdout_matches?(stdout) && stderr_matches?(stderr)
      rescue Errno::ENOENT
        false
      end
    end

    failure_message do |actual|
      actual.call.last
    end

    chain :with_status do |status|
      @status = status
    end

    chain :succesfully do
      @status = 0
    end

    chain :unsuccesfully do
      @status = 1
    end

    chain :with_stdout do |stdout|
      @stdout = stdout
    end

    chain :with_stderr do |stderr|
      @stderr = stderr
    end

    chain :with_no_stderr do
      @stderr = ''
    end

    def status_matches?(actual)
      @status.nil? || @status == actual.exitstatus
    end

    def stdout_matches?(actual)
      @stdout.nil? || regexp_match?(@stdout, actual)
    end

    def stderr_matches?(actual)
      @stderr.nil? || regexp_match?(@stderr, actual)
    end

    def regexp_match?(exp, actual)
      if exp.is_a? Regexp
        actual.match?(exp)
      else
        exp == actual
      end
    end
  end
end
