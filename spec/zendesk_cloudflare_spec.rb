# rubocop:disable LineLength

require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered! uncovered: 4

describe CloudflareClient do
  let(:client) { CloudflareClient.new(auth_key: "somefakekey", email: "foo@bar.com") }
  let(:valid_zone_id) { 'abc1234' }
  let(:valid_org_id) { 'def5678' }
  let(:valid_user_id) { 'someuserid' }
  let(:valid_user_email) { 'user@example.com' }
  let(:valid_iso8601_ts) { '2016-11-11T12:00:00Z' }

  it "initializes correctly" do
    CloudflareClient.new(auth_key: "auth_key", email: "foo@bar.com")
  end

  it "raises when missing auth_key" do
    expect { CloudflareClient.new }.to raise_error(RuntimeError, "Missing auth_key")
  end

  it "raises when missing auth_email" do
    expect { CloudflareClient.new(auth_key: "somefakekey") }.to raise_error(RuntimeError, "missing email")
  end

  describe "virtual dns analytics" do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/user/virtual_dns/foo/dns_analytics/report?dimensions%5B%5D=foo&limit=100&metrics%5B%5D=bar&since=2016-11-11T12:00:00Z&until=2016-11-11T12:00:00Z").
        to_return(response_body(SUCCESSFUL_VIRTUAL_DNS_TABLE))
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/def5678/virtual_dns/foo/dns_analytics/report?dimensions%5B%5D=foo&limit=100&metrics%5B%5D=bar&since=2016-11-11T12:00:00Z&until=2016-11-11T12:00:00Z").
        to_return(response_body(SUCCESSFUL_VIRTUAL_DNS_TABLE))
    end

    it "fails to retrieve summarized metrics over a time period" do
      expect do
        client.virtual_dns_analytics
      end.to raise_error(ArgumentError, 'missing keywords: id, scope, dimensions, metrics, since_ts, until_ts')

      expect do
        client.virtual_dns_analytics(
          id:         'foo',
          scope:      'bar',
          dimensions: 'foo',
          metrics:    'bar',
          since_ts:   'foo',
          until_ts:   'bar'
        )
      end.to raise_error(RuntimeError, 'scope must be user or organization')

      expect do
        client.virtual_dns_analytics(
          id:         'foo',
          scope:      'user',
          dimensions: 'foo',
          metrics:    'bar',
          since_ts:   'foo',
          until_ts:   'bar'
        )
      end.to raise_error(RuntimeError, 'dimensions must ba an array of possible dimensions')

      expect do
        client.virtual_dns_analytics(
          id:         'foo',
          scope:      'user',
          dimensions: ['foo'],
          metrics:    'bar',
          since_ts:   'foo',
          until_ts:   'bar'
        )
      end.to raise_error(RuntimeError, 'metrics must ba an array of possible metrics')

      expect do
        client.virtual_dns_analytics(
          id:         'foo',
          scope:      'user',
          dimensions: ['foo'],
          metrics:    ['bar'],
          since_ts:   'foo',
          until_ts:   'bar'
        )
      end.to raise_error(RuntimeError, 'since_ts must be a valid iso8601 timestamp')

      expect do
        client.virtual_dns_analytics(
          id:         'foo',
          scope:      'user',
          dimensions: ['foo'],
          metrics:    ['bar'],
          since_ts:   valid_iso8601_ts,
          until_ts:   'bar'
        )
      end.to raise_error(RuntimeError, 'until_ts must be a valid iso8601 timestamp')

      expect do
        client.virtual_dns_analytics(
          id:         'foo',
          scope:      'organization',
          dimensions: ['foo'],
          metrics:    ['bar'],
          since_ts:   valid_iso8601_ts,
          until_ts:   valid_iso8601_ts
        )
      end.to raise_error(RuntimeError, 'org_id required')
    end

    it "retrieves summarized metrics over a time period (user)" do
      result = client.virtual_dns_analytics(
        id:         'foo',
        scope:      'user',
        dimensions: ['foo'],
        metrics:    ['bar'],
        since_ts:   valid_iso8601_ts,
        until_ts:   valid_iso8601_ts
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_VIRTUAL_DNS_TABLE, symbolize_names: true))
    end

    it "retrieves summarized metrics over a time period (organization)" do
      result = client.virtual_dns_analytics(
        id:         'foo',
        scope:      'organization',
        org_id:     valid_org_id,
        dimensions: ['foo'],
        metrics:    ['bar'],
        since_ts:   valid_iso8601_ts,
        until_ts:   valid_iso8601_ts
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_VIRTUAL_DNS_TABLE, symbolize_names: true))
    end
  end

  describe "logs api" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/logs/requests?start=1495825365').
        to_return(response_body(SUCCESSFULL_LOG_MESSAGE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/logs/requests?end=1495825610&start=1495825365').
        to_return(response_body(SUCCESSFULL_LOG_MESSAGE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/logs/requests/somerayid').
        to_return(response_body(SUCCESSFULL_LOG_MESSAGE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/logs/requests/foo?count=5&end=1495825610&start_id=foo').
        to_return(response_body(SUCCESSFULL_LOG_MESSAGE))
    end

    let(:valid_start_time) { 1495825365 }
    let(:valid_end_time) { 1495825610 }

    it "fails to get logs via timestamps" do
      expect { client.get_logs_by_time }.to raise_error(ArgumentError, 'missing keywords: zone_id, start_time')

      expect do
        client.get_logs_by_time(zone_id: nil, start_time: valid_start_time)
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.get_logs_by_time(zone_id: valid_zone_id, start_time: nil)
      end.to raise_error(RuntimeError, 'start_time required')
    end

    it "fails with invalid timestamps" do
      expect do
        client.get_logs_by_time(zone_id: valid_zone_id, start_time: 'bob')
      end.to raise_error(RuntimeError, 'start_time must be a valid unix timestamp')

      expect do
        client.get_logs_by_time(zone_id: valid_zone_id, start_time: valid_start_time, end_time: 'cat')
      end.to raise_error(RuntimeError, 'end_time must be a valid unix timestamp')
    end

    it "get's logs via timestamps" do
      # note, these are raw not json encoded
      result = client.get_logs_by_time(zone_id: valid_zone_id, start_time: valid_start_time)
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE, symbolize_names: true))
      result = client.get_logs_by_time(zone_id: valid_zone_id, start_time: valid_start_time, end_time: valid_end_time)
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE, symbolize_names: true))
    end

    it "fails to get a log by rayid" do
      expect { client.get_log }.to raise_error(ArgumentError, 'missing keywords: zone_id, ray_id')
    end

    it "get's a log via rayid" do
      result = client.get_log(zone_id: valid_zone_id, ray_id: 'somerayid')
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE, symbolize_names: true))
    end

    it "fails to get logs since a given ray_id" do
      expect { client.get_logs_since }.to raise_error(ArgumentError, 'missing keywords: zone_id, ray_id')

      expect do
        client.get_logs_since(zone_id: valid_zone_id, ray_id: 'foo', end_time: 'bob')
      end.to raise_error(RuntimeError, 'end time must be a valid unix timestamp')
    end

    it "gets logs since a given ray_id" do
      result = client.get_logs_since(zone_id: valid_zone_id, ray_id: 'foo', end_time: valid_end_time, count: 5)
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE, symbolize_names: true))
    end
  end
end
