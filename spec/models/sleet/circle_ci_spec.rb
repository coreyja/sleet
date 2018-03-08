
# frozen_string_literal: true

require 'spec_helper'

describe Sleet::CircleCi, type: :model do
  describe '.get' do
    let!(:stubbed_request) { stub_request(:get, 'http://circleci.com').with(query: { 'circle-token' => 'FAKE_TOKEN' }) }

    it 'adds the token as a query param and only reads the token from disk once' do
      described_class.get 'http://circleci.com', 'FAKE_TOKEN'
      expect(stubbed_request).to have_been_requested.once
    end
  end
end
