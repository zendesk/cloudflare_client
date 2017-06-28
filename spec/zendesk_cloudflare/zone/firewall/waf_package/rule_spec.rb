require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered!

describe CloudflareClient::Zone::Firewall::WAFPackage::Rule do
  subject(:client) do
    described_class.new(zone_id: zone_id, package_id: package_id, auth_key: 'somefakekey', email: 'foo@bar.com')
  end

  let(:zone_id) { 'abc1234' }
  let(:package_id) { 'bcd2345' }

  it_behaves_like 'initialize for zone firewall waf package features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/waf/packages/#{package_id}/rules?direction=desc&match=all&order=priority&page=1&per_page=50").
        to_return(response_body(waf_packages_rule_list))
    end

    let(:waf_packages_rule_list) { create(:waf_packages_rule_list) }

    it 'returns a list of waf rules' do
      expect(client.list).to eq(waf_packages_rule_list)
    end

    it 'fails to list waf rules' do
      expect do
        client.list(match: 'cat')
      end.to raise_error(RuntimeError, "match must be one of #{described_class::VALID_MATCHES}")

      expect do
        client.list(order: 'bird')
      end.to raise_error(RuntimeError, "order must be one of #{described_class::VALID_ORDERS}")

      expect do
        client.list(direction: 'bar')
      end.to raise_error(RuntimeError, "direction must be one of #{described_class::VALID_DIRECTIONS}")
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages/#{package_id}/rules/#{id}").
        to_return(response_body(waf_packages_rule_show))
    end

    let(:waf_packages_rule_show) { create(:waf_packages_rule_show) }
    let(:id) { 'some_rule_id' }

    it 'gets details for a single waf rule' do
      expect(client.show(id: id)).to eq(waf_packages_rule_show)
    end

    it 'fails to get a waf rule' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/waf/packages/#{package_id}/rules/#{id}").
        with(body: payload).
        to_return(response_body(waf_packages_rule_show))
    end

    let(:waf_packages_rule_show) { create(:waf_packages_rule_show, result: result) }
    let(:result) { create(:waf_packages_rule_result, mode: mode) }
    let(:id) { 'some_rule_id' }
    let(:mode) { 'on' }
    let(:payload) { {mode: mode} }

    it 'updates a waf rule' do
      expect(client.update(id: id, mode: mode)).to eq(waf_packages_rule_show)
    end

    it 'fails to update a waf rule' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, mode: 'boom')
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")
    end
  end
end
