# frozen_string_literal: true

require 'spec_helper'

describe Sleet, type: :model do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end
end
