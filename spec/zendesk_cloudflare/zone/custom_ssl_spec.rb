require 'spec_helper'
require 'zendesk_cloudflare/zone/custom_ssl'

SingleCov.covered!

describe CloudflareClient::Zone::CustomSSL do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#create' do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_certificates').
        with(body: payload).
        to_return(response_body(custom_ssl_show))
    end

    let(:custom_ssl_show) { create(:custom_ssl_show) }
    let(:payload) { {certificate: 'blahblah', private_key: 'pkstring', bundle_method: 'force'} }

    it 'creates custom ssl for a zone' do
      result = client.create(payload)

      expect(result).to eq(custom_ssl_show)
    end

    it 'fails to create custom ssl for a zone' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: certificate, private_key')

      expect do
        client.create(private_key: nil, certificate: 'bar')
      end.to raise_error(RuntimeError, 'private_key required')

      expect do
        client.create(private_key: 'foo', certificate: nil)
      end.to raise_error(RuntimeError, 'certificate required')

      expect do
        client.create(certificate: 'foo', private_key: 'bar', bundle_method: 'foobar')
      end.to raise_error(RuntimeError, "valid bundle methods are #{CloudflareClient::VALID_BUNDLE_METHODS}")
    end
  end

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_certficates?direction=asc&match=all&page=1&per_page=50").
        to_return(response_body(custom_ssl_list))
    end

    let(:custom_ssl_list) { create(:custom_ssl_list) }

    it 'lists all custom ssl configurations' do
      expect(client.list).to eq(custom_ssl_list)
    end

    it 'fails to list all custom ssl configurations' do
      expect do
        client.list(order: 'foo')
      end.to raise_error(RuntimeError, "order must be one of #{described_class::VALID_ORDERS}")

      expect do
        client.list(order: 'status', direction: 'foo')
      end.to raise_error(RuntimeError, 'direction must be asc || desc')

      expect do
        client.list(order: 'status', direction: 'asc', match: 'foo')
      end.to raise_error(RuntimeError, 'match must be all || any')

      expect do
        client.list(order: 'status', direction: 'desc', match: 'foo')
      end.to raise_error(RuntimeError, 'match must be all || any')
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_certificates/#{configuration_id}").
        to_return(response_body(custom_ssl_show))
    end

    let(:custom_ssl_show) { create(:custom_ssl_show) }
    let(:configuration_id) { 'foobar' }

    it 'returns details of a custom ssl configuration' do
      expect(client.show(configuration_id: configuration_id)).to eq(custom_ssl_show)
    end

    it 'fails to get details for a custom configuration' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: configuration_id')
      expect { client.show(configuration_id: nil) }.to raise_error(RuntimeError, 'ssl configuration id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_certificates/#{configuration_id}").
        with(body: {certificate: certificate, private_key: private_key, bundle_method: bundle_method}).
        to_return(response_body(custom_ssl_show))
    end

    let(:custom_ssl_show) { create(:custom_ssl_show, result: custom_ssl_result) }
    let(:custom_ssl_result) { create(:custom_ssl_result, bundle_method: bundle_method) }
    let(:configuration_id) { 'foobar' }
    let(:certificate) { 'a certificate' }
    let(:private_key) { 'a private_key' }
    let(:bundle_method) { CloudflareClient::VALID_BUNDLE_METHODS.sample }

    it 'updates a custom ssl config' do
      result = client.update(
        id:            configuration_id,
        certificate:   certificate,
        private_key:   private_key,
        bundle_method: bundle_method
      )

      expect(result).to eq(custom_ssl_show)
    end

    it 'fails to update a custom ssl config' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: configuration_id, certificate: certificate, private_key: private_key, bundle_method: 'foo')
      end.to raise_error(RuntimeError, "valid bundle methods are #{CloudflareClient::VALID_BUNDLE_METHODS}")
    end
  end

  describe '#prioritize' do
    before do
      stub_request(:put, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_certificates/prioritize").
        with(body: data.to_json).
        to_return(response_body(custom_ssl_list))
    end

    let(:custom_ssl_list) do
      create(:custom_ssl_list, result_count: 2, result: [custom_ssl_result1, custom_ssl_result2])
    end
    let(:custom_ssl_result1) { create(:custom_ssl_result, priority: 12) }
    let(:custom_ssl_result2) { create(:custom_ssl_result, priority: 1) }
    let(:data) { custom_ssl_list[:result].map { |r| {id: r[:id], priority: r[:priority]} } }

    it 'updates the prioritiy of custom ssl certificates' do
      expect(client.prioritize(data: data)).to eq(custom_ssl_list)
    end

    it 'fails to prioritize ssl configurations' do
      expect { client.prioritize }.to raise_error(RuntimeError, 'must provide an array of certifiates and priorities')

      expect do
        client.prioritize(data: {foo: 'bar'})
      end.to raise_error(RuntimeError, 'must provide an array of certifiates and priorities')
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_certificates/#{configuration_id}").
        to_return(response_body(custom_ssl_delete))
    end

    let(:custom_ssl_delete) { create(:custom_ssl_delete, id: configuration_id) }
    let(:configuration_id) { '7e7b8deba8538af625850b7b2530034c' }

    it 'deletes a custom ssl configuration' do
      expect(client.delete(id: configuration_id)).to eq(custom_ssl_delete)
    end

    it 'fails to delete a custom ssl configuration' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
