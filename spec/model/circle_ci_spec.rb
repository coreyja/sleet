
# frozen_string_literal: true

require 'spec_helper'

describe Sleet::CircleCi, type: :model do
  describe '.get' do
    let(:url) { 'http://circleci.com' }
    let!(:stubbed_request) { stub_request(:get, url).with(query: { 'circle-token' => 'FAKE_TOKEN' }) }

    before do
      allow(File).to receive(:read).and_return('FAKE_TOKEN')
      allow(Dir).to receive(:home).and_return('/HOME')
    end

    after do
      expect(Dir).to have_received(:home).once
      expect(File).to have_received(:read).with('/HOME/.circleci.token').once
    end

    it 'adds the token as a query param' do
      2.times { described_class.get url }
      expect(stubbed_request).to have_been_requested.times(2)
    end
  end
end
