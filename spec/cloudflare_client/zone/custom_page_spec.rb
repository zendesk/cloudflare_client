require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::CustomPage do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_pages").
        to_return(response_body(successful_custom_page_list))
    end

    let(:successful_custom_page_list) { create(:successful_custom_page_list) }

    it 'lists custom pages' do
      expect(client.list).to eq(successful_custom_page_list)
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_pages/#{custom_page_id}").
        to_return(response_body(successful_custom_page_show))
    end

    let(:successful_custom_page_show) { create(:successful_custom_page_show) }
    let(:custom_page_id) { 'foobar' }

    it 'gets details for a custom page' do
      expect(client.show(id: custom_page_id)).to eq(successful_custom_page_show)
    end

    it 'fails to get details for a custom page' do
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id must not be nil')
    end
  end

  describe '#update' do
    before do
      stub_request(:put, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/custom_pages/#{custom_page_id}").
        with(body: {url: url, state: state}).
        to_return(response_body(successful_custom_page_show))
    end

    let(:successful_custom_page_show) { create(:successful_custom_page_show, result: successful_custom_page_result) }
    let(:successful_custom_page_result) { create(:successful_custom_page_result, url: url, state: state) }
    let(:custom_page_id) { 'foobar' }
    let(:url) { 'http://foo.bar' }
    let(:state) { 'customized' }

    it 'updates a custom page' do
      result = client.update(id: custom_page_id, url: url, state: state)

      expect(result).to eq(successful_custom_page_show)
    end

    it 'fails to update a custom page' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keywords: :id, :url, :state')
      expect { client.update(id: nil, url: url, state: state) }.to raise_error(RuntimeError, 'id required')
      expect { client.update(id: custom_page_id, url: nil, state: state) }.to raise_error(RuntimeError, 'url required')

      expect do
        client.update(id: custom_page_id, url: url, state: 'whateverman')
      end.to raise_error(RuntimeError, 'state must be either default | customized')
    end
  end
end
