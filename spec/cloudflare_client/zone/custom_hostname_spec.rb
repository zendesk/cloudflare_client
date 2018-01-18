require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::CustomHostname do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#create' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames").
        to_return(response_body(custom_hostname_show))
    end

    let(:custom_hostname_show) { create(:custom_hostname_show) }

    it 'creates a custom hostname' do
      result = client.create(hostname: 'somerandomhost')
      expect(result).to eq(custom_hostname_show)
    end

    it 'fails to create a custom_hostname' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keyword: hostname')
      expect { client.create(hostname: nil) }.to raise_error(RuntimeError, 'hostname required')

      expect do
        client.create(hostname: 'footothebar', ssl: { type: 'dv', method: 'snail' })
      end.to raise_error(RuntimeError, "method must be one of #{described_class::VALID_METHODS}")

      expect do
        client.create(hostname: 'footothebar', ssl: { type: 'snail', method: 'http' })
      end.to raise_error(RuntimeError, "type must be one of #{described_class::VALID_TYPES}")
    end
  end

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames?direction=desc&order=ssl&page=1&per_page=50&ssl=0").
        to_return(response_body(custom_hostname_list1))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames?direction=desc&id=#{id}&order=ssl&page=1&per_page=50&ssl=0").
        to_return(response_body(custom_hostname_list2))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames?direction=desc&hostname=#{hostname}&order=ssl&page=1&per_page=50&ssl=0").
        to_return(response_body(custom_hostname_list3))
    end

    let(:custom_hostname_list1) { create(:custom_hostname_list) }
    let(:custom_hostname_list2) { create(:custom_hostname_list) }
    let(:custom_hostname_list3) { create(:custom_hostname_list) }
    let(:id) { '12345' }
    let(:hostname) { 'foobar' }

    it 'lists custom_hostnames' do
      expect(client.list).to eq(custom_hostname_list1)
      expect(client.list(id: id)).to eq(custom_hostname_list2)
      expect(client.list(hostname: hostname)).to eq(custom_hostname_list3)
    end

    it 'fails to list custom hostnames' do
      expect { client.list(hostname: hostname, id: id) }.to raise_error(RuntimeError, 'cannot use both hostname and id')

      expect do
        client.list(order: 'invalid')
      end.to raise_error(RuntimeError, "order must be one of #{described_class::VALID_ORDERS}")

      expect do
        client.list(direction: 'invalid')
      end.to raise_error(RuntimeError, "direction must be one of #{described_class::VALID_DIRECTIONS}")

      expect do
        client.list(ssl: 'invalid')
      end.to raise_error(RuntimeError, "ssl must be one of #{[0, 1]}")
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames/#{id}").
        to_return(response_body(custom_hostname_show))
    end

    let(:custom_hostname_show) { create(:custom_hostname_show) }
    let(:id) { '12345' }

    it 'returns details for a custom hostname' do
      expect(client.show(id: id)).to eq(custom_hostname_show)
    end

    it 'fails to get details for a custom hostname' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames/#{id}").
        with(body: {ssl: {method: method, type: type}}).
        to_return(response_body(custom_hostname_show1))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames/#{id}").
        with(body: {ssl: {method: method, type: type}, custom_origin_server: custom_origin_server}).
        to_return(response_body(custom_hostname_show2))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames/#{id}").
        with(body: {ssl: {method: method, type: type}, custom_origin_server: custom_origin_server, custom_metadata: {foo: 'bar'}}).
        to_return(response_body(custom_hostname_show3))
    end

    let(:custom_hostname_show1) { create(:custom_hostname_show) }
    let(:custom_hostname_show2) { create(:custom_hostname_show) }
    let(:custom_hostname_show3) { create(:custom_hostname_show_with_metadata) }
    let(:id) { 'foo' }
    let(:method) { 'http' }
    let(:type) { 'dv' }
    let(:custom_origin_server) { 'footothebar' }

    it 'updates a custom hostname' do
      result = client.update(id: id, ssl: { method: method, type: type })
      expect(result).to eq(custom_hostname_show1)

      result = client.update(id: id, ssl: { method: method, type: type }, custom_origin_server: custom_origin_server)
      expect(result).to eq(custom_hostname_show2)

      result = client.update(id: id, ssl: { method: method, type: type }, custom_origin_server: custom_origin_server, custom_metadata: {foo: 'bar'})
      expect(result).to eq(custom_hostname_show3)
    end

    it 'fails to update a custom_hostname' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.update(id: nil, ssl: { method: method, type: type }) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, ssl: { method: 'invalid_method', type: type })
      end.to raise_error(RuntimeError, "method must be one of #{described_class::VALID_METHODS}")

      expect do
        client.update(id: id, ssl: { method: method, type: 'invalid type' })
      end.to raise_error(RuntimeError, "type must be one of #{described_class::VALID_TYPES}")

      expect do
        client.update(id: id, ssl: { method: method, type: type }, custom_metadata: 'bob')
      end.to raise_error(RuntimeError, 'custom_metadata must be an object')
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_hostnames/#{id}").
        to_return(response_body(custom_hostname_delete))
    end

    let(:custom_hostname_delete) { create(:custom_hostname_delete) }
    let(:id) { 'foo' }

    it 'deletes a custom_hostname' do
      expect(client.delete(id: id)).to eq(custom_hostname_delete)
    end

    it 'fails to delete a custom_hostname' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
