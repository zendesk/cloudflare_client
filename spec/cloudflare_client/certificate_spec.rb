require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Certificate do
  subject(:client) { described_class.new(auth_key: 'somefakekey', email: 'foo@bar.com') }

  describe '#list' do
    before { stub_request(:get, request_url).to_return(response_body(certificate_list)) }

    let(:certificate_list) { create(:certificate_list) }
    let(:request_path) { '/certificates' }

    it 'lists cloudflare certs' do
      expect(client.list).to eq(certificate_list)
    end
  end

  describe '#create' do
    before { stub_request(:post, request_url).with(body: payload).to_return(response_body(certificate_show)) }

    let(:certificate_show) { create(:certificate_show) }
    let(:request_path) { '/certificates' }
    let(:hostnames) { rand(2..4).times.map { Faker::Internet.domain_name } }
    let(:requested_validity) { described_class::VALID_REQUESTED_VALIDITIES.sample }
    let(:request_type) { described_class::VALID_REQUEST_TYPES.sample }
    let(:csr) { certificate_show[:result][:csr] }
    let(:payload) do
      {
        hostnames:          hostnames,
        requested_validity: requested_validity,
        request_type:       request_type,
        csr:                csr
      }
    end

    it 'creates a certificate' do
      expect(client.create(**payload)).to eq(certificate_show)
    end

    it 'fails to create a certificate' do
      error_message = 'missing keyword: :hostnames'
      expect { client.create }.to raise_error(ArgumentError, error_message)

      error_message = 'hostnames must be an array of hostnames'
      expect { client.create(hostnames: 'foo') }.to raise_error(RuntimeError, error_message)

      error_message = 'hostnames must be an array of hostnames'
      expect { client.create(hostnames: []) }.to raise_error(RuntimeError, error_message)

      error_message = "requested_validity must be one of #{described_class::VALID_REQUESTED_VALIDITIES}"
      expect { client.create(hostnames: hostnames, requested_validity: 1) }.to raise_error(RuntimeError, error_message)

      error_message = "request_type must be one of #{described_class::VALID_REQUEST_TYPES}"
      expect do
        client.create(hostnames: hostnames, requested_validity: requested_validity, request_type: 'bob')
      end.to raise_error(RuntimeError, error_message)
    end
  end

  describe '#show' do
    before { stub_request(:get, request_url).to_return(response_body(certificate_show)) }

    let(:certificate_show) { create(:certificate_show) }
    let(:request_path) { "/certificates/#{id}" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }

    it 'shows details for a certificate' do
      expect(client.show(id: id)).to eq(certificate_show)
    end

    it 'fails to show details of a certficate' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#revoke' do
    before { stub_request(:delete, request_url).to_return(response_body(certificate_revoke)) }

    let(:certificate_revoke) { create(:certificate_revoke) }
    let(:request_path) { "/certificates/#{id}" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }

    it 'revokes a certificate' do
      expect(client.revoke(id: id)).to eq(certificate_revoke)
    end

    it 'fails to revoke a certificate' do
      expect { client.revoke }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.revoke(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
