require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Namespace::Value do
  subject(:client) { described_class.new(account_id: account_id, namespace_id: namespace_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:account_id) { 'abc1234' }
  let(:namespace_id) { 'def5678' }
  let(:key) { 'My-Key' }
  let(:value1) { 'Some Value' }
  let(:value2) { 'Another Value' }
  let(:value3) { 'More Value' }
  let(:expiration_ttl) { 500 }
  let(:metadata) { '{"someMetadataKey": "someMetadataValue"}' }

  describe '#write' do
    before do
      stub_request(:put, "https://api.cloudflare.com/client/v4/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}").
        with(body: "Some Value").
        to_return(response_body(value_write))
      stub_request(:put, "https://api.cloudflare.com/client/v4/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}?expiration_ttl=#{expiration_ttl}").
        with(body: "Another Value", query: {expiration_ttl: 500}).
        to_return(response_body(value_write))
      stub_request(:put, "https://api.cloudflare.com/client/v4/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}").
        with(body: "{\"value\":\"More Value\",\"metadata\":\"{\\\"someMetadataKey\\\": \\\"someMetadataValue\\\"}\"}").
        to_return(response_body(value_write))
    end

    let(:value_write) { create(:value_write) }
    
    it 'writes a value identified by a key' do
      expect(client.write(key: key, value: value1)).to eq(value_write)
    end

    it 'writes a value identified by a key with expiration TTL' do
      expect(client.write(key: key, value: value2, expiration_ttl: 500)).to eq(value_write)
    end

    it 'writes a value identiifed by a key with metadata' do
      expect(client.write(key: key, value: value3, metadata: metadata)).to eq(value_write)
    end

    it 'fails to write a value identified by a key' do
      expect { client.write(key: 'key') }.to raise_error(ArgumentError, 'missing keyword: :value')
      expect { client.write(value: 'value') }.to raise_error(ArgumentError, 'missing keyword: :key')

      expect { client.write(key: 'key', value: 'value', expiration_ttl: '500') }.to raise_error(RuntimeError, "expiration_ttl must be an integer")
    end
  end

  describe '#read' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}").
        to_return(response_body(value_read))
    end

    let(:value_read) { Faker::Alphanumeric.alpha(number: 10) }

    it 'returns the value associated with the given key in the given namespace' do
      expect(client.read(key: key)).to eq(value_read)
    end

    it 'fails to return the value associated with the given key in the given namespace' do
      expect { client.read }. to raise_error(ArgumentError, 'missing keyword: :key')
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}").
        to_return(response_body(value_delete))
    end

    let(:value_delete) { create(:value_write) }

    it 'removes a KV pair from the Namespace' do
      expect(client.delete(key: key)).to eq(value_delete)
    end

    it 'fails to delete a KV pair from the namesapce' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: :key')
    end
  end
end

