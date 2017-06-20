require 'spec_helper'
require 'zendesk_cloudflare/zone/analytics'

SingleCov.covered!

describe CloudflareClient::Zone::Analytics do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#zone_dashboard' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/analytics/dashboard").
        to_return(response_body(successful_zone_analytics_dashboard))
    end

    let(:successful_zone_analytics_dashboard) { create(:successful_zone_analytics_dashboard) }

    it 'returns zone analytics dashboard' do
      expect(client.zone_dashboard).to eq(successful_zone_analytics_dashboard)
    end
  end

  describe '#colo_dashboard' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/analytics/dashboard").
        to_return(response_body(successful_colo_analytics_dashboard))
    end

    let(:successful_colo_analytics_dashboard) { create(:successful_colo_analytics_dashboard) }

    it 'returns colo analytics dashboard' do
      result = client.colo_dashboard(since_ts: '2015-01-01T12:23:00Z', until_ts: '2015-02-01T12:23:00Z')
      expect(result).to eq(successful_colo_analytics_dashboard)
    end

    it 'fails to return colo analytics dashboard' do
      expect do
        client.colo_dashboard(since_ts: 'blah')
      end.to raise_error(RuntimeError, 'since_ts must be a valid timestamp')

      expect do
        client.colo_dashboard(since_ts: '2015-01-01T12:23:00Z', until_ts: 'blah')
      end.to raise_error(RuntimeError, 'until_ts must be a valid timestamp')
    end
  end

  describe '#dns_table' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/dns_analytics/report").
        to_return(response_body(successful_dns_analytics_table))
    end

    let(:successful_dns_analytics_table) { create(:successful_dns_analytics_table) }

    it 'returns dns analytics' do
      expect(client.dns_table).to eq(successful_dns_analytics_table)
    end
  end

  describe '#dns_by_time' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/dns_analytics/report/bytime?limit=#{limit}&since=#{since_ts}&time_delta=#{time_delta}&until=#{until_ts}").
        to_return(response_body(successful_dns_analytics_table))
    end

    let(:successful_dns_analytics_table) { create(:successful_dns_analytics_table) }
    let(:limit) { 100 }
    let(:time_delta) { 'hour' }
    let(:since_ts) { Time.now.utc.advance(days: -1).iso8601 }
    let(:until_ts) { Time.now.utc.iso8601 }
    let(:options) do
      {
        since_ts:   since_ts,
        until_ts:   until_ts,
        limit:      limit,
        time_delta: time_delta
      }
    end

    it 'returns dns analytics by time' do
      expect(client.dns_by_time(options)).to eq(successful_dns_analytics_table)
    end

    it 'fails to return dns bytime analytics' do
      expect do
        client.dns_by_time(since_ts: 'foo')
      end.to raise_error(RuntimeError, 'since_ts must be a valid timestamp')

      expect do
        client.dns_by_time(since_ts: '2015-01-01T12:23:00Z', until_ts: 'foo')
      end.to raise_error(RuntimeError, 'until_ts must be a valid timestamp')
    end
  end
end
