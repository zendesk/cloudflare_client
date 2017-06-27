require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered!

describe CloudflareClient::Zone::RailgunConnections do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }
  let(:railgun_id) { 'e928d310693a83094309acf9ead50448' }

  it_behaves_like 'initialize for zone features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/railguns").
        to_return(response_body(successful_railgun_connections_list))
    end

    let(:successful_railgun_connections_list) { create(:successful_railgun_connections_list) }

    it 'lists railguns' do
      expect(client.list).to eq(successful_railgun_connections_list)
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/railguns/#{successful_railgun_connections_show[:result][:id]}").
        to_return(response_body(successful_railgun_connections_show))
    end

    let(:successful_railgun_connections_show) { create(:successful_railgun_connections_show) }
    let(:railgun_id) { successful_railgun_connections_show[:result][:id] }

    it 'railguns connection details' do
      expect(client.show(id: railgun_id)).to eq(successful_railgun_connections_show)
    end

    it 'fails to get railgun connection details' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'railgun id required')
    end
  end

  describe '#test' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/railguns/#{railgun_id}/diagnose").
        to_return(response_body(successful_railgun_connections_test))
    end

    let(:successful_railgun_connections_test) { create(:successful_railgun_connections_test) }

    it 'tests railgun connection' do
      expect(client.test(id: railgun_id)).to eq(successful_railgun_connections_test)
    end

    it 'fails to test a railgun connection' do
      expect { client.test }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.test(id: nil) }.to raise_error(RuntimeError, 'railgun id required')
    end
  end

  describe '#connect' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/railguns/#{railgun_id}").
        with(body: {connected: true}).
        to_return(response_body(successful_railgun_connections_connect))
    end

    let(:successful_railgun_connections_connect) { create(:successful_railgun_connections_connect) }

    it 'connects a railgun' do
      expect(client.connect(id: railgun_id)).to eq(successful_railgun_connections_connect)
    end

    it 'fails to connect a railgun' do
      expect { client.connect }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.connect(id: nil) }.to raise_error(RuntimeError, 'railgun id required')
    end
  end

  describe '#disconnect' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/railguns/#{railgun_id}").
        with(body: {connected: false}).
        to_return(response_body(successful_railgun_connections_disconnect))
    end

    let(:successful_railgun_connections_disconnect) { create(:successful_railgun_connections_disconnect) }

    it 'disconnects a railgun' do
      expect(client.disconnect(id: railgun_id)).to eq(successful_railgun_connections_disconnect)
    end

    it 'fails to disconnect a railgun' do
      expect { client.disconnect }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.disconnect(id: nil) }.to raise_error(RuntimeError, 'railgun id required')
    end
  end
end
