require 'spec_helper'
require 'zendesk_cloudflare/zone/ssl'

SingleCov.covered!

describe CloudflareClient::Zone::SSL do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#analyze' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/ssl/analyze").
        with(body: payload).
        to_return(response_body(ssl_analyze))
    end

    let(:ssl_analyze) { create(:ssl_analyze) }
    let(:certificate) { 'bar' }
    let(:bundle_method) { 'ubiquitous' }
    let(:payload) { {certificate: certificate, bundle_method: bundle_method} }

    it 'analyzies a certificate' do
      expect(client.analyze(certificate: certificate, bundle_method: bundle_method)).to eq(ssl_analyze)
    end

    it 'fails to analyze a certificate' do
      expect do
        client.analyze(bundle_method: 'foo')
      end.to raise_error(RuntimeError, "valid bundle methods are #{described_class::VALID_BUNDLE_METHODS}")
    end
  end

  describe '#verification' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/ssl/verification").
        to_return(response_body(ssl_verification))
    end

    let(:ssl_verification) { create(:ssl_verification) }

    it 'verifies a zone' do
      expect(client.verification).to eq(ssl_verification)
    end

    it 'fails to verify a zone' do
      expect do
        client.verification(retry_verification: false)
      end.to raise_error(RuntimeError, "retry_verification must be one of #{described_class::VALID_RETRY_VERIFICATIONS}")
    end

    context 'with retry_verification' do
      before do
        stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/ssl/verification?retry=#{retry_verification}").
          to_return(response_body(ssl_verification))
      end

      let(:retry_verification) { true }

      it 'verifies a zone' do
        expect(client.verification(retry_verification: retry_verification)).to eq(ssl_verification)
      end
    end
  end
end
