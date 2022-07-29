require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Organization::AccessRule do
  subject(:client) { described_class.new(org_id: org_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:org_id) { SecureRandom.hex(16) }

  it_behaves_like 'initialize for organization features'

  describe '#list' do
    before { stub_request(:get, request_url).to_return(response_body(organization_access_rule_list)) }

    let(:organization_access_rule_list) { create(:organization_access_rule_list) }
    let(:request_path) { "/organizations/#{org_id}/firewall/access_rules/rules" }
    let(:request_query) do
      {
        notes:                notes,
        mode:                 mode,
        match:                match,
        configuration_value:  configuration_value,
        order:                order,
        configuration_target: configuration_target,
        direction:            direction,
        page:                 page,
        per_page:             per_page
      }
    end
    let(:notes) { 'some notes' }
    let(:mode) { described_class::VALID_MODES.sample }
    let(:match) { described_class::VALID_MATCHES.sample }
    let(:configuration_value) { 'some_configuration_value' }
    let(:order) { described_class::VALID_ORDERS.sample }
    let(:configuration_target) { described_class::VALID_CONFIG_TARGETS.sample }
    let(:direction) { described_class::VALID_DIRECTIONS.sample }
    let(:page) { 1 }
    let(:per_page) { 50 }

    it 'lists organization level firewall rules' do
      expect(client.list(**request_query)).to eq(organization_access_rule_list)
    end

    it 'fails to list organization level firewall rules' do
      expect { client.list(notes: {abc: 123}) }.to raise_error(RuntimeError, 'notes must be a String')

      expect do
        client.list(mode: 'invalid_mode')
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")

      expect do
        client.list(match: 'invalid_match')
      end.to raise_error(RuntimeError, "match must be one of #{described_class::VALID_MATCHES}")

      expect do
        client.list(order: 'invalid_order')
      end.to raise_error(RuntimeError, "order must be one of #{described_class::VALID_ORDERS}")

      expect do
        client.list(configuration_target: 'invalid_configuration_target')
      end.to raise_error(RuntimeError, "configuration_target must be one of #{described_class::VALID_CONFIG_TARGETS}")

      expect do
        client.list(direction: 'invalid_direction')
      end.to raise_error(RuntimeError, "direction must be one of #{described_class::VALID_DIRECTIONS}")
    end
  end

  describe '#create' do
    before do
      stub_request(:post, request_url)
        .with(body: payload)
        .to_return(response_body(organization_access_rule_show))
    end

    let(:organization_access_rule_show) { create(:organization_access_rule_show) }
    let(:request_path) { "/organizations/#{org_id}/firewall/access_rules/rules" }
    let(:mode) { described_class::VALID_MODES.sample }
    let(:configuration) { create(:organization_access_rule_configuration) }
    let(:payload) { {mode: mode, configuration: configuration} }

    it 'creates an org level access rules' do
      expect(client.create(**payload)).to eq(organization_access_rule_show)
    end

    it 'fails to create an org level access rule' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: :mode, :configuration')

      expect do
        client.create(mode: mode, configuration: 'foo')
      end.to raise_error(RuntimeError, 'configuration must be an hash of configuration')

      expect do
        client.create(mode: 'foo', configuration: configuration)
      end.to raise_error(RuntimeError, "mode must be one of #{described_class::VALID_MODES}")
    end

    context 'when notes is given' do
      let(:notes) { 'some notes' }
      let(:payload) { {mode: mode, configuration: configuration, notes: notes} }

      it 'creates an org level access rules' do
        expect(client.create(**payload)).to eq(organization_access_rule_show)
      end
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, request_url).to_return(response_body(organization_access_rule_delete))
    end

    let(:organization_access_rule_delete) { create(:organization_access_rule_delete) }
    let(:request_path) { "/organizations/#{org_id}/firewall/access_rules/rules/#{id}" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }

    it 'deletes an org level access rule' do
      expect(client.delete(id: id)).to eq(organization_access_rule_delete)
    end

    it 'fails to delete an org level access rule' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
