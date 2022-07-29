require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::Firewall::WAFPackage do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages?direction=#{direction}&match=#{match}&name=#{name}&order=#{order}&page=1&per_page=50").
        to_return(response_body(firewall_waf_package_list))
    end

    let(:firewall_waf_package_list) { create(:firewall_waf_package_list) }
    let(:order) { 'status' }
    let(:direction) { 'asc' }
    let(:match) { 'any' }
    let(:name) { 'bar' }

    it 'gets waf rule packages' do
      result = client.list(order: order, direction: direction, match: match, name: name)
      expect(result).to eq(firewall_waf_package_list)
    end

    it 'fails to get waf rule packages' do
      expect do
        client.list(order: 'foo')
      end.to raise_error(RuntimeError, "order must be one of #{described_class::VALID_ORDERS}")

      expect do
        client.list(direction: 'foo')
      end.to raise_error(RuntimeError, "direction must be one of #{described_class::VALID_DIRECTIONS}")

      expect do
        client.list(match: 'foo')
      end.to raise_error(RuntimeError, "match must be one of #{described_class::VALID_MATCHES}")
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages/#{id}").
        to_return(response_body(firewall_waf_package_show))
    end

    let(:firewall_waf_package_show) { create(:firewall_waf_package_show) }
    let(:id) { 'foo' }

    it 'gets a waf rule package' do
      expect(client.show(id: id)).to eq(firewall_waf_package_show)
    end

    it 'fails to get package details' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end


  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages/#{id}").
        with(body: payload).
        to_return(response_body(firewall_waf_package_show))
    end

    let(:firewall_waf_package_show) { create(:firewall_waf_package_show, result: result) }
    let(:result) { create(:firewall_waf_package_result, sensitivity: sensitivity, action_mode: action_mode) }
    let(:id) { 'foo' }
    let(:sensitivity) { 'high' }
    let(:action_mode) { 'challenge' }
    let(:payload) { {sensitivity: sensitivity, action_mode: action_mode} }

    it 'updates a waf rule package' do
      result = client.update(id: id, sensitivity: sensitivity, action_mode: action_mode)
      expect(result).to eq(firewall_waf_package_show)
    end

    it 'fails to change the anomaly detection settings of a waf package' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, sensitivity: 'bar')
      end.to raise_error(RuntimeError, "sensitivity must be one of #{described_class::VALID_SENSITIVITIES}")

      expect do
        client.update(id: id, sensitivity: sensitivity, action_mode: 'bar')
      end.to raise_error(RuntimeError, "action_mode must be one of #{described_class::VALID_ACTION_MODES}")
    end
  end
end
