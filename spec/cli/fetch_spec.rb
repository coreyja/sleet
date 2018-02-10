
# frozen_string_literal: true

require 'spec_helper'

describe 'sleet fetch', type: :cli do
  context 'when NOT in a git repo' do
    it 'fails' do
      expect_command('fetch').to run.unsuccesfully
    end
  end
end
