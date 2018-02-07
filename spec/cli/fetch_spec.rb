
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet fetch', type: :cli do
  it 'runs successfully' do
    output, error, status = Open3.capture3("#{cli_executable_path} fetch")
    expect(status.success?).to eq true
    expect(output).to match(/^Sleet v/)
    expect(error).to eq ''
  end
end
