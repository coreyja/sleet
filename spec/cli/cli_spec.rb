
# frozen_string_literal: true

require 'spec_helper'

describe 'The CLI App', type: :aruba do
  let(:sleet_command_path) { '../../exe/sleet' }
  it 'has a test' do
    Rugged::Repository.init_at('.')

    `#{sleet_command_path}`
    expect($CHILD_STATUS.exitstatus).to eq 0
  end
end
