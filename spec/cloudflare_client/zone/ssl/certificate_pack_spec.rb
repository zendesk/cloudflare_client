require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::SSL::CertificatePack do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/ssl/certificate_packs").
        to_return(response_body(certificate_pack_list))
    end

    let(:certificate_pack_list) { create(:certificate_pack_list) }

    it 'lists certificate packs' do
      expect(client.list).to eq(certificate_pack_list)
    end
  end

  describe '#order' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/ssl/certificate_packs").
        with(body: payload).
        to_return(response_body(certificate_pack_show))
    end

    let(:certificate_pack_show) { create(:certificate_pack_show) }
    let(:hosts) { %w[foobar.com] }
    let(:payload) { {hosts: hosts} }

    it 'orders certificate packs' do
      expect(client.order(hosts: hosts)).to eq(certificate_pack_show)
    end

    it 'fails to order certificate packs' do
      expect { client.order(hosts: 'foo') }.to raise_error(RuntimeError, 'hosts must be an array of hosts')
    end

    context 'when hosts is nil' do
      let(:hosts) { nil }

      it 'orders certificate packs' do
        expect(client.order(hosts: hosts)).to eq(certificate_pack_show)
      end
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/ssl/certificate_packs/#{id}").
        with(body: payload).
        to_return(response_body(certificate_pack_show))
    end

    let(:certificate_pack_show) { create(:certificate_pack_show) }
    let(:id) { 'some_cert_pack_id' }
    let(:hosts) { %w[foobar.com] }
    let(:payload) { {hosts: hosts} }

    it 'updates a certifiate pack' do
      expect(client.update(id: id, hosts: hosts)).to eq(certificate_pack_show)
    end

    it 'fails to update a certificate pack' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keywords: :id, :hosts')
      expect { client.update(id: nil, hosts: hosts) }.to raise_error(RuntimeError, 'id required')
      expect { client.update(id: id, hosts: []) }.to raise_error(RuntimeError, 'hosts must be an array of hosts')
    end

    context 'when hosts is nil' do
      let(:hosts) { nil }

      it 'updates a certifiate pack' do
        expect(client.update(id: id, hosts: hosts)).to eq(certificate_pack_show)
      end
    end
  end
end
