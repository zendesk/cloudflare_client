require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered!

describe CloudflareClient::Organization::Member do
  subject(:client) { described_class.new(org_id: org_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:org_id) { SecureRandom.hex(16) }
  let(:user_id) { SecureRandom.hex(16) }

  it_behaves_like 'initialize for organization features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/members").
        to_return(response_body(organization_member_list))
    end

    let(:organization_member_list) { create(:organization_member_list) }

    it 'returns a list of org members' do
      expect(client.list).to eq(organization_member_list)
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/members/#{user_id}").
        to_return(response_body(organization_member_show))
    end

    let(:organization_member_show) { create(:organization_member_show) }

    it 'gets the details for an org member' do
      expect(client.show(id: user_id)).to eq(organization_member_show)
    end

    it 'fails to get details for an org member' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/members/#{user_id}").
        with(body: payload).
        to_return(response_body(organization_member_show))
    end

    let(:organization_member_show) { create(:organization_member_show) }
    let(:roles) { rand(1..3).times.map { SecureRandom.hex(16) } }
    let(:payload) { {roles: roles} }

    it 'updates an org members roles' do
      expect(client.update(id: user_id, roles: roles)).to eq(organization_member_show)
    end

    it 'fails to updates org member roles' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keywords: id, roles')
      expect { client.update(id: nil, roles: nil) }.to raise_error(RuntimeError, 'id required')
      expect { client.update(id: user_id, roles: nil) }.to raise_error(RuntimeError, 'roles must be an array of roles')
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/members/#{user_id}").
        to_return(response_body(organization_member_delete))
    end

    let(:organization_member_delete) { create(:organization_member_delete) }

    it 'removes and org member' do
      expect(client.delete(id: user_id)).to eq(organization_member_delete)
    end

    it 'fails to remove an org member' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
