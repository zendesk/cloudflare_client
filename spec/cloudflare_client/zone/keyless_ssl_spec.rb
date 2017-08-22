require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::KeylessSSL do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#create' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/keyless_certificates").
        with(body: payload).
        to_return(response_body(keyless_ssl_show))
    end

    let(:keyless_ssl_show) { create(:keyless_ssl_show) }
    let(:host) { 'foobar' }
    let(:name) { "#{host} Keyless SSL" }
    let(:port) { 1245 }
    let(:certificate) { 'cert data' }
    let(:bundle_method) { 'ubiquitous' }
    let(:payload) { {host: host, name: name, port: port, certificate: certificate, bundle_method: bundle_method} }

    it 'creates a keyless ssl config' do
      expect(client.create(host: host, certificate: certificate, port: port)).to eq(keyless_ssl_show)
    end

    it 'fails to create a keyless ssl config' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: host, port, certificate')
      expect { client.create(host: nil, port: 1234, certificate: 'bar') }.to raise_error(RuntimeError, 'host required')

      expect do
        client.create(host: 'foo', port: 1234, certificate: nil)
      end.to raise_error(RuntimeError, 'certificate required')

      expect do
        client.create(host: 'foobar', port: 1234, certificate: 'cert data', bundle_method: 'foo')
      end.to raise_error(RuntimeError, "valid bundle methods are #{CloudflareClient::VALID_BUNDLE_METHODS}")
    end

    context 'when a name is given' do
      let(:name) { 'a name' }

      it 'creates a keyless ssl config' do
        expect(client.create(host: host, name: name, certificate: certificate, port: port)).to eq(keyless_ssl_show)
      end
    end
  end

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/keyless_certificates").
        to_return(response_body(keyless_ssl_list))
    end

    let(:keyless_ssl_list) { create(:keyless_ssl_list) }

    it 'lists all keyless ssl configs' do
      expect(client.list).to eq(keyless_ssl_list)
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/keyless_certificates/#{id}").
        to_return(response_body(keyless_ssl_show))
    end

    let(:keyless_ssl_show) { create(:keyless_ssl_show) }
    let(:id) { '4d2844d2ce78891c34d0b6c0535a291e' }

    it 'shows details of a keyless_ssl_config' do
      expect(client.show(id: id)).to eq(keyless_ssl_show)
    end

    it 'fails to list details of a keless_ssl_config' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/keyless_certificates/#{id}").
        with(body: payload).
        to_return(response_body(keyless_ssl_show))
    end

    let(:keyless_ssl_show) { create(:keyless_ssl_show) }
    let(:id) { '4d2844d2ce78891c34d0b6c0535a291e' }
    let(:host) { 'foo.com' }
    let(:name) { "#{host} Keyless SSL" }
    let(:enabled) { true }
    let(:port) { 1234 }
    let(:payload) { {host: host, name: name, port: port, enabled: enabled} }

    it 'updates a keyless ssl config' do
      expect(client.update(id: id, host: host, port: port, enabled: enabled)).to eq(keyless_ssl_show)
    end

    it 'fails to update a keyless_ssl_config' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')
      expect { client.update(id: id, enabled: 'foo') }.to raise_error(RuntimeError, 'enabled must be true||false')
    end

    context 'when a name is given' do
      let(:name) { 'a name' }

      it 'updates a keyless ssl config' do
        expect(client.update(id: id, host: host, name: name, port: port, enabled: enabled)).to eq(keyless_ssl_show)
      end
    end

    context 'when enabled is not given' do
      let(:payload) { {host: host, name: name, port: port} }

      it 'updates a keyless ssl config' do
        expect(client.update(id: id, host: host, port: port)).to eq(keyless_ssl_show)
      end
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/keyless_certificates/#{id}").
        to_return(response_body(keyless_ssl_delete))
    end

    let(:keyless_ssl_delete) { create(:keyless_ssl_delete) }
    let(:id) { '4d2844d2ce78891c34d0b6c0535a291e' }

    it 'deletes a keyless ssl config' do
      expect(client.delete(id: id)).to eq(keyless_ssl_delete)
    end

    it 'fails to delete a keyless ssl config' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
