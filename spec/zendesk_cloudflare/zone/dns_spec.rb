require 'spec_helper'
require 'zendesk_cloudflare/zone/dns'

SingleCov.covered!

describe CloudflareClient::Zone::DNS do
  subject(:client) { described_class.new(zone_id: valid_zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  before do
    stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/dns_records').
      to_return(response_body(successful_dns_create))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/dns_records?content=192.168.1.1&name=foobar.com&order=type&page=1&per_page=50').
      to_return(response_body(successful_dns_query))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/dns_records/somebigid').
      to_return(response_body(successful_dns_query))
    stub_request(:put, 'https://api.cloudflare.com/client/v4/zones/abc1234/dns_records/somebigid').
      to_return(response_body(successful_dns_update))
    stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/dns_records/somebigid').
      to_return(response_body(successful_dns_delete))
  end

  let(:successful_dns_create) { create(:successful_dns_create) }
  let(:successful_dns_query) { create(:successful_dns_query) }
  let(:successful_dns_update) { create(:successful_dns_update) }
  let(:successful_dns_delete) { create(:successful_dns_delete) }
  let(:valid_zone_id) { 'abc1234' }

  describe '#initialize' do
    it 'returns a CloudflareClient::Zone::DNS instance' do
      expect { subject }.to_not raise_error
      expect(subject).to be_a(described_class)
    end

    context 'when zone_id is missing' do
      let(:valid_zone_id) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(StandardError, 'zone_id required')
      end
    end
  end

  describe '#create' do
    it 'creates a dns record' do
      result = client.create(name: 'foobar.com', type: 'CNAME', content: '192.168.1.1')
      expect(result).to eq(successful_dns_create)
    end

    it 'raises if args are missing' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: name, type, content')
    end

    it 'raises if in invalid type is given' do
      expect do
        client.create(name: 'blah', type: 'invalid_type', content: 'content')
      end.to raise_error(RuntimeError, "type must be one of #{described_class::VALID_TYPES}")
    end
  end

  describe '#list' do
    it 'list dns records' do
      result = client.list(name: 'foobar.com', content: '192.168.1.1')
      expect(result).to eq(successful_dns_query)
    end

    it 'raises if match is not all or any' do
      expect { client.list(match: 'invalid') }.to raise_error(RuntimeError, 'match must be either all | any')
    end
  end

  describe '#show' do
    it 'returns a specfic dns record' do
      expect(client.show(id: 'somebigid')).to eq(successful_dns_query)
    end

    it 'raises if dns record id is missing' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'dns record id required')
    end
  end

  describe '#update' do
    it 'fails to update a record' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keywords: id, type, name, content')

      expect do
        client.update(id: nil, name: 'foo', type: 'foo', content: 'foo')
      end.to raise_error(RuntimeError, 'dns record id required')
    end

    it 'updates a dns record' do
      result = client.update(
        id:      'somebigid',
        type:    'CNAME',
        name:    'foobar',
        content: '10.1.1.1'
      )

      expect(result).to eq(successful_dns_update)
    end
  end

  describe '#delete' do
    it 'fails to delete a dns record' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it 'deletes a dns record' do
      result = client.delete(id: 'somebigid')
      expect(result).to eq(successful_dns_delete)
    end
  end

  def response_body(body)
    {body: body.to_json, headers: {'Content-Type': 'application/json'}}
  end
end
