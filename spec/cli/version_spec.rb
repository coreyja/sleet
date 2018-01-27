
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet version', type: :aruba do
  let(:sleet_command_path) { '../../exe/sleet' }

  it 'has the correct prefix' do
    expect(`#{sleet_command_path} version`).to match(/^Sleet v/)
  end
end
