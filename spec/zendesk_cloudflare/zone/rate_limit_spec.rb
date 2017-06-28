require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered!

describe CloudflareClient::Zone::RateLimit do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/rate_limits?page=1&per_page=50").
        to_return(response_body(rate_limit_list))
    end

    let(:rate_limit_list) { create(:rate_limit_list) }

    it 'lists rate limits for a zone' do
      expect(client.list).to eq(rate_limit_list)
    end
  end

  describe '#create' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/rate_limits").
        with(body: payload).
        to_return(response_body(rate_limit_show))
    end

    let(:rate_limit_show) { create(:rate_limit_show, result: rate_limit_result) }
    let(:rate_limit_result) { create(:rate_limit_result, match: match, action: action) }
    let(:match) { create(:rate_limit_match) }
    let(:action) { create(:rate_limit_action) }
    let(:threshold) { 2 }
    let(:disabled) { true }
    let(:period) { 30 }
    let(:payload) { {match: match, threshold: threshold, period: period, action: action, disabled: disabled} }

    it 'creates a zone rate limit' do
      result = client.create(match: match, action: action, threshold: threshold, disabled: disabled, period: period)

      expect(result).to eq(rate_limit_show)
    end

    it 'fails to create a zone rate limit' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: match, threshold, period, action')

      expect do
        client.create(match: 'foo', action: {}, threshold: 1, period: 2)
      end.to raise_error(RuntimeError, "match must be a match object #{described_class::DOC_URL}")

      expect do
        client.create(match: {}, action: 'foo', threshold: 1, period: 2)
      end.to raise_error(RuntimeError, "action must be a action object #{described_class::DOC_URL}")

      expect do
        client.create(match: {}, action: {}, threshold: 'foo', period: 2)
      end.to raise_error(RuntimeError, 'threshold must be between 1 86400')

      expect do
        client.create(match: {}, action: {}, threshold: 0, period: 2)
      end.to raise_error(RuntimeError, 'threshold must be between 1 86400')

      expect do
        client.create(match: {}, action: {}, threshold: 1, period: 'foo')
      end.to raise_error(RuntimeError, 'period must be between 1 86400')

      expect do
        client.create(match: {}, action: {}, threshold: 1, period: 0)
      end.to raise_error(RuntimeError, 'period must be between 1 86400')

      expect do
        client.create(match: {}, action: {}, threshold: 2, period: 1, disabled: 'foo')
      end.to raise_error(RuntimeError, "disabled must be one of #{[true, false]}")

      expect do
        client.create(match: {}, action: {}, threshold: 2, period: 1, disabled: 'blah')
      end.to raise_error(RuntimeError, "disabled must be one of #{[true, false]}")
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/rate_limits/#{id}").
        to_return(response_body(rate_limit_show))
    end

    let(:rate_limit_show) { create(:rate_limit_show, id: id) }
    let(:id) { '372e67954025e0ba6aaa6d586b9e0b59' }

    it 'returns details for a zone rate limit' do
      expect(client.show(id: id)).to eq(rate_limit_show)
    end

    it 'fails to return details for a zone rate limit' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:put, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/rate_limits/#{id}").
        with(body: payload).
        to_return(response_body(rate_limit_show))
    end

    let(:rate_limit_show) { create(:rate_limit_show, result: rate_limit_result) }
    let(:rate_limit_result) { create(:rate_limit_result, match: match, action: action) }
    let(:match) { create(:rate_limit_match) }
    let(:action) { create(:rate_limit_action) }
    let(:id) { '372e67954025e0ba6aaa6d586b9e0b59' }
    let(:threshold) { 50 }
    let(:disabled) { false }
    let(:period) { 100 }
    let(:description) { 'foo to the bar' }
    let(:payload) do
      {
        id:          id,
        match:       match,
        threshold:   threshold,
        period:      period,
        action:      action,
        disabled:    disabled,
        description: description
      }
    end

    it 'updates a zone rate limit' do
      expect(client.update(payload)).to eq(rate_limit_show)
    end

    it 'fails to update a zone rate limit' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keywords: id, match, action, threshold, period')

      expect do
        client.update(id: nil, match: nil, action: nil, threshold: nil, period: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, match: nil, action: nil, threshold: nil, period: nil)
      end.to raise_error(RuntimeError, "match must be a match object #{described_class::DOC_URL}")

      expect do
        client.update(id: id, match: {}, action: nil, threshold: 1, period: nil)
      end.to raise_error(RuntimeError, "action must be a action object #{described_class::DOC_URL}")

      expect do
        client.update(id: id, match: {}, action: {}, threshold: nil, period: nil)
      end.to raise_error(RuntimeError, 'threshold must be between 1 86400')

      expect do
        client.update(id: id, match: {}, action: {}, threshold: 50, period: 'foo')
      end.to raise_error(RuntimeError, 'period must be between 1 86400')

      expect do
        client.update(id: id, match: {}, action: {}, threshold: 50, period: 200, disabled: 'foo')
      end.to raise_error(RuntimeError, "disabled must be one of #{[true, false]}")
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/rate_limits/#{id}").
        to_return(response_body(rate_limit_delete))
    end

    let(:rate_limit_delete) { create(:rate_limit_delete, id: id) }
    let(:id) { '372e67954025e0ba6aaa6d586b9e0b59' }

    it 'deletes a zone rate limit' do
      result = client.delete(id: id)
      expect(result).to eq(rate_limit_delete)
    end

    it 'fails to delete a zone rate limit' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
