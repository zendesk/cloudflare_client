require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::Firewall::WAFPackage::RuleGroup do
  subject(:client) do
    described_class.new(zone_id: zone_id, package_id: package_id, auth_key: 'somefakekey', email: 'foo@bar.com')
  end

  let(:zone_id) { 'abc1234' }
  let(:package_id) { 'bcd2345' }

  it_behaves_like 'initialize for zone firewall waf package features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups?direction=desc&match=all&mode=on&order=mode&page=1&per_page=50").
        to_return(response_body(waf_packages_rule_group_list))
    end

    let(:waf_packages_rule_group_list) { create(:waf_packages_rule_group_list) }

    it 'lists waf rule groups' do
      expect(client.list).to eq(waf_packages_rule_group_list)
    end

    it 'fails to list waf rule groups' do
      expect do
        client.list(mode: 'foo')
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")

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
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups/#{id}").
        to_return(response_body(waf_packages_rule_group_show))
    end

    let(:waf_packages_rule_group_show) { create(:waf_packages_rule_group_show) }
    let(:id) { 'some_group_id' }

    it 'gets details of a single waf group' do
      expect(client.show(id: id)).to eq(waf_packages_rule_group_show)
    end

    it 'fails to get details for a single waf group' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups/#{id}").
        with(body: payload).
        to_return(response_body(waf_packages_rule_group_show))
    end

    let(:waf_packages_rule_group_show) { create(:waf_packages_rule_group_show, result: result) }
    let(:result) { create(:waf_packages_rule_group_result, mode: mode) }
    let(:id) { 'some_group_id' }
    let(:mode) { 'off' }
    let(:payload) { {mode: mode} }

    it 'updates a waf group' do
      expect(client.update(id: id, mode: mode)).to eq(waf_packages_rule_group_show)
    end

    it 'fails to update a waf group' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, mode: 'blah')
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")
    end
  end
end
