require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered!

describe CloudflareClient::Zone::Subscription do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }
  let(:subscription_show) { create(:subscription_show) }

  it_behaves_like 'initialize for zone features'

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/subscription").
        to_return(response_body(subscription_show))
    end

    it 'shows a zone subscription' do
      expect(client.show).to eq(subscription_show)
    end
  end

  describe '#create' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/subscription").
        with(body: payload).
        to_return(response_body(subscription_show))
    end

    let(:price) { 20 }
    let(:currency) { 'USD' }
    let(:id) { 'some_subscription_id' }
    let(:frequency) { described_class::VALID_FREQUENCIES.sample }
    let(:component_values) { create_list(:subscription_component_value, 1) }
    let(:rate_plan) { create(:subscription_rate_plan) }
    let(:zone) { create(:subscription_zone) }
    let(:state) { described_class::VALID_STATES.sample }
    let(:payload) do
      {
        price:            price,
        currency:         currency,
        id:               id,
        frequency:        frequency,
        component_values: component_values,
        rate_plan:        rate_plan,
        zone:             zone,
        state:            state
      }
    end

    it 'creates a zone subscription' do
      expect(client.create(payload)).to eq(subscription_show)
    end

    it 'fails to create a zone subscription' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: price, currency, id, frequency')

      expect do
        client.create(price: nil, currency: currency, id: id, frequency: frequency)
      end.to raise_error(RuntimeError, 'price must be a Numeric')

      expect do
        client.create(price: 'foo', currency: currency, id: id, frequency: frequency)
      end.to raise_error(RuntimeError, 'price must be a Numeric')

      expect do
        client.create(price: price, currency: nil, id: id, frequency: frequency)
      end.to raise_error(RuntimeError, 'currency must be a String')

      expect do
        client.create(price: price, currency: 123, id: id, frequency: frequency)
      end.to raise_error(RuntimeError, 'currency must be a String')

      expect do
        client.create(price: price, currency: currency, id: nil, frequency: frequency)
      end.to raise_error(RuntimeError, 'id must be a String')

      expect do
        client.create(price: price, currency: currency, id: 123, frequency: frequency)
      end.to raise_error(RuntimeError, 'id must be a String')

      expect do
        client.create(price: price, currency: currency, id: SecureRandom.hex(17), frequency: frequency)
      end.to raise_error(RuntimeError, 'the length of id must not exceed 32')

      expect do
        client.create(price: price, currency: currency, id: id, frequency: nil)
      end.to raise_error(RuntimeError, "frequency must be one of #{described_class::VALID_FREQUENCIES}")

      expect do
        client.create(price: price, currency: currency, id: id, frequency: 'foo')
      end.to raise_error(RuntimeError, "frequency must be one of #{described_class::VALID_FREQUENCIES}")

      expect do
        client.create(price: price, currency: currency, id: id, frequency: frequency, state: 'foo')
      end.to raise_error(RuntimeError, "state must be one of #{described_class::VALID_STATES}")
    end
  end
end
