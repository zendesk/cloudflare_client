require 'spec_helper'
require 'zendesk_cloudflare/organization/invite'

SingleCov.covered!

describe CloudflareClient::Organization::Invite do
  subject(:client) { described_class.new(org_id: org_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:org_id) { SecureRandom.hex(16) }

  it_behaves_like 'initialize for organization features'

  describe '#list' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/invites").
        with(body: payload).
        to_return(response_body(organization_invite_show))
    end

    let(:organization_invite_show) { create(:organization_invite_show) }
    let(:email) { Faker::Internet.email }
    let(:roles) { rand(1..3).times.map { SecureRandom.hex(16) } }
    let(:auto_accept) { Faker::Boolean.boolean }
    let(:payload) { {invited_member_email: email, roles: roles, auto_accept: auto_accept} }

    it 'creates an organization invite' do
      expect(client.create(email: email, roles: roles, auto_accept: auto_accept)).to eq(organization_invite_show)
    end

    it 'fails to create an organization invite' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: email, roles')
      expect { client.create(email: nil, roles: roles) }.to raise_error(RuntimeError, 'email must be a String')

      expect do
        client.create(email: Faker::Lorem.characters(91), roles: roles)
      end.to raise_error(RuntimeError, 'the length of email must not exceed 90')

      expect do
        client.create(email: email, roles: 'foo')
      end.to raise_error(RuntimeError, 'roles must be an array of roles')

      expect do
        client.create(email: email, roles: [])
      end.to raise_error(RuntimeError, 'roles must be an array of roles')

      expect do
        client.create(email: email, roles: roles, auto_accept: 'foo')
      end.to raise_error(RuntimeError, "auto_accept must be one of #{[true, false]}")
    end

    context 'when auto_accept is nil' do
      let(:auto_accept) { nil }
      let(:payload) { {invited_member_email: email, roles: roles} }

      it 'creates an organization invite' do
        expect(client.create(email: email, roles: roles, auto_accept: auto_accept)).to eq(organization_invite_show)
      end
    end
  end

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/invites").
        to_return(response_body(organization_invite_list))
    end

    let(:organization_invite_list) { create(:organization_invite_list) }

    it 'lists invutes for an organization' do
      expect(client.list).to eq(organization_invite_list)
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/invites/#{invite_id}").
        to_return(response_body(organization_invite_show))
    end

    let(:organization_invite_show) { create(:organization_invite_show) }
    let(:invite_id) { SecureRandom.hex(16) }

    it 'gets details of an organization invite' do
      expect(client.show(id: invite_id)).to eq(organization_invite_show)
    end

    it 'fails to list details of an organization invite' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/invites/#{invite_id}").
        to_return(response_body(organization_invite_show))
    end

    let(:organization_invite_show) { create(:organization_invite_show) }
    let(:invite_id) { SecureRandom.hex(16) }
    let(:roles) { rand(1..3).times.map { SecureRandom.hex(16) } }

    it 'updates the roles for an organization invite' do
      expect(client.update(id: invite_id, roles: roles)).to eq(organization_invite_show)
    end

    it 'fails to update the roles for an organization invite' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keywords: id, roles')
      expect { client.update(id: nil, roles: roles) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: invite_id, roles: nil)
      end.to raise_error(RuntimeError, 'roles must be an array of roles')

      expect do
        client.update(id: invite_id, roles: [])
      end.to raise_error(RuntimeError, 'roles must be an array of roles')
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/organizations/#{org_id}/invites/#{invite_id}").
        to_return(response_body(organization_invite_delete))
    end

    let(:organization_invite_delete) { create(:organization_invite_delete) }
    let(:invite_id) { SecureRandom.hex(16) }

    it 'deletes an organization invites' do
      expect(client.delete(id: invite_id)).to eq(organization_invite_delete)
    end

    it 'fails to delete an org invite' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
