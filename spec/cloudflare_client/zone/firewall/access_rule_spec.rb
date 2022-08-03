require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::Firewall::AccessRule do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/access_rules/rules?configuration_target=#{configuration_target}&direction=#{direction}&match=#{match}&mode=#{mode}&order=#{order}&page=1&per_page=50&scope_type=#{scope_type}").
        to_return(response_body(firewall_access_rule_list))
    end

    let(:firewall_access_rule_list) { create(:firewall_access_rule_list) }
    let(:mode) { 'block' }
    let(:match) { 'all' }
    let(:scope_type) { 'zone' }
    let(:configuration_target) { 'country' }
    let(:direction) { 'asc' }
    let(:order) { 'scope_type' }

    it 'lists firewall access rules' do
      result = client.list(
        mode:                 mode,
        match:                match,
        scope_type:           scope_type,
        configuration_target: configuration_target,
        direction:            direction,
        order:                order
      )

      expect(result).to eq(firewall_access_rule_list)
    end

    it 'fails to list firewall access rules' do
      expect do
        client.list(mode: 'foo')
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")

      expect do
        client.list(match: 'foo')
      end.to raise_error(RuntimeError, "match must be one of #{described_class::VALID_MATCHES}")

      expect do
        client.list(scope_type: 'foo')
      end.to raise_error(RuntimeError, "scope_type must be one of #{described_class::VALID_SCOPE_TYPES}")

      expect do
        client.list(configuration_target: 'foo')
      end.to raise_error(RuntimeError, "configuration_target must be one of #{described_class::VALID_CONFIG_TARGETS}")

      expect do
        client.list(direction: 'foo')
      end.to raise_error(RuntimeError, "direction must be one of #{described_class::VALID_DIRECTIONS}")

      expect do
        client.list(order: 'foo')
      end.to raise_error(RuntimeError, "order must be one of #{described_class::VALID_ORDERS}")
    end
  end

  describe '#create' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/access_rules/rules").
        with(body: payload).
        to_return(response_body(firewall_access_rule_show))
    end

    let(:firewall_access_rule_show) { create(:firewall_access_rule_show, result: firewall_access_rule_result) }
    let(:firewall_access_rule_result) { create(:firewall_access_rule_result, configuration: configuration, mode: mode) }
    let(:configuration) { create(:firewall_access_rule_configuration) }
    let(:mode) { 'block' }
    let(:payload) { {mode: mode, configuration: configuration} }

    it 'creates a new firewall access rule' do
      expect(client.create(mode: mode, configuration: configuration)).to eq(firewall_access_rule_show)
    end

    it 'fails to create a firewall access rule' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: :mode, :configuration')

      expect do
        client.create(mode: 'foo', configuration: 'foo')
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")

      expect do
        client.create(mode: mode, configuration: 'foo')
      end.to raise_error(RuntimeError, 'configuration must be a valid configuration object')

      expect do
        client.create(mode: mode, configuration: {foo: 'bar'})
      end.to raise_error(RuntimeError, 'configuration must contain valid a valid target and value')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/access_rules/rules/#{id}").
        with(body: payload).
        to_return(response_body(firewall_access_rule_show))
    end

    let(:firewall_access_rule_show) { create(:firewall_access_rule_show, result: firewall_access_rule_result) }
    let(:firewall_access_rule_result) { create(:firewall_access_rule_result, mode: mode, notes: notes) }
    let(:id) { 'foo' }
    let(:mode) { 'block' }
    let(:notes) { 'foo to the bar' }
    let(:payload) { {mode: mode, notes: notes} }

    it 'updates a firewall access rule' do
      expect(client.update(id: id, mode: mode, notes: notes)).to eq(firewall_access_rule_show)
    end

    it 'fails to updates a firewall access rule' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, mode: 'foo')
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/firewall/access_rules/rules/#{id}").
        to_return(response_body(firewall_access_rule_delete))
    end

    let(:firewall_access_rule_delete) { create(:firewall_access_rule_delete) }
    let(:id) { 'foo' }
    let(:cascade) { 'basic' }

    it 'deletes a firewall access rule' do
      expect(client.delete(id: id, cascade: cascade)).to eq(firewall_access_rule_delete)
    end

    it 'fails to delete a firewall access rule' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.delete(id: id, cascade: 'cat')
      end.to raise_error(RuntimeError, "cascade must be one of #{described_class::VALID_CASCADES}")
    end
  end
end
