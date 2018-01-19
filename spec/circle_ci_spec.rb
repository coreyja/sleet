
# frozen_string_literal: true

require 'spec_helper'

describe Sleet::CircleCi do
  describe '.get' do
    let(:url) { 'http://circleci.com' }
    let!(:stubbed_request) { stub_request(:get, url).with(query: { 'circle-token' => 'FAKE_TOKEN' }) }

    before do
      allow(File).to receive(:read).and_return('FAKE_TOKEN')
    end

    it 'adds the token as a query param' do
      described_class.get url
      expect(stubbed_request).to have_been_requested
    end
  end
end
