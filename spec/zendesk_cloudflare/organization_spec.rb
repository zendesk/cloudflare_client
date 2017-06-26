require 'spec_helper'
require 'zendesk_cloudflare/organization'

SingleCov.covered!

describe CloudflareClient::Organization do
  subject(:client) { described_class.new(org_id: org_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:org_id) { SecureRandom.hex(16) }
  let(:organization_show) { create(:organization_show) }

  it_behaves_like 'initialize for organization features'

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{org_id}").
        to_return(response_body(organization_show))
    end

    it 'shows an the details of the organization' do
      expect(client.show).to eq(organization_show)
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/organizations/#{org_id}").
        with(body: payload).
        to_return(response_body(organization_show))
    end

    let(:name) { 'foobar.com' }
    let(:payload) { {name: name} }

    it 'updates an org' do
      expect(client.update(name: name)).to eq(organization_show)
    end

    context 'when name is nil' do
      let(:payload) { nil }

      it 'updates an org' do
        expect(client.update).to eq(organization_show)
      end
    end
  end
end
