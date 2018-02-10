
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet version', type: :cli do
  it 'has the correct prefix' do
    expect_command('version').to run.succesfully.with_stdout(/^Sleet v/).with_no_stderr
  end
end
