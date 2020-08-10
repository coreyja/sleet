# frozen_string_literal: true

require 'spec_helper'

describe Sleet::CircleCi, type: :model do
  describe '.get' do
    context 'without server redirect' do
      let!(:stubbed_request) do
        stub_request(:get, 'http://circleci.com').with(query: { 'circle-token' => 'FAKE_TOKEN' })
      end

      it 'adds the token as a query param and only reads the token from disk once' do
        described_class.get 'http://circleci.com', 'FAKE_TOKEN'
        expect(stubbed_request).to have_been_requested.once
      end
    end

    context 'with server redirect' do
      let!(:stubbed_redirect) do
        stub_request(:get, 'http://circleci.com')
          .with(query: { 'circle-token' => 'FAKE_TOKEN' })
          .to_return(
            status: 301,
            body: 'Your are being redirected',
            headers: { Location: 'http://s3.amazonaws.com/file' }
          )
      end
      let!(:stubbed_request) do
        stub_request(:get, 'http://s3.amazonaws.com/file')
      end

      it 'adds the token as a query param and only reads the token from disk once' do
        described_class.get 'http://circleci.com', 'FAKE_TOKEN'
        expect(stubbed_redirect).to have_been_requested.once
        expect(stubbed_request).to have_been_requested.once
      end
    end
  end
end
