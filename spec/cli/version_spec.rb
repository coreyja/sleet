
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet version', type: :cli do
  it 'has the correct prefix' do
    expect(`#{cli_executable_path} version`).to match(/^Sleet v/)
    expect($CHILD_STATUS.exitstatus).to eq 0
  end
end
