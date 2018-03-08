
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet version', type: :cli do
  it 'has the correct prefix' do
    expect_command('version').to output(/^Sleet v/).to_stdout.and output_nothing.to_stderr
  end

  it 'outputs only the version when given the bare option' do
    expect_command('version --bare').to output(/\d+\.\d+\.\d+/).to_stdout.and without_error
  end

  context 'some specs for the demo' do
    it 'this one fails' do
      expect(true).to eq false
    end

    it 'this one fails too' do
      expect(1 + 1).to eq 4
    end

    it 'this one also fails' do
      expect('a').to eq 'b'
    end
  end
end
