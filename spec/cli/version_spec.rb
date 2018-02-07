
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet version', type: :cli do
  it 'corey has implemented custom matchers' do
    # 'https://relishapp.com/rspec/rspec-expectations/v/3-1/docs/custom-matchers/define-matcher-with-fluent-interface'
    expect(true).to eq false
  end

  it 'has the correct prefix' do
    output, error, status = Open3.capture3("#{cli_executable_path} version")
    expect(output).to match(/^Sleet v/)
    expect(error).to eq ''
    expect(status.success?).to eq true
  end
end
