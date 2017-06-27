require 'spec_helper'
require 'zendesk_cloudflare/organization/role'

SingleCov.covered!

describe CloudflareClient::Organization::Role do
  subject(:client) { described_class.new(org_id: org_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:org_id) { SecureRandom.hex(16) }

  it_behaves_like 'initialize for organization features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/roles").
        to_return(response_body(organization_role_list))
    end

    let(:organization_role_list) { create(:organization_role_list) }

    it 'lists organization roles' do
      expect(client.list).to eq(organization_role_list)
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/roles/#{role_id}").
        to_return(response_body(organization_role_show))
    end

    let(:organization_role_show) { create(:organization_role_show) }
    let(:role_id) { SecureRandom.hex(16) }

    it 'shows details of an organization role' do
      result = client.show(id: role_id)
      expect(result).to eq(organization_role_show)
    end

    it 'fails to get details of an organization role' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
