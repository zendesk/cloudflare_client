# rubocop:disable LineLength

require 'spec_helper'

# Yikes!
SingleCov.covered! uncovered: 52

describe CloudflareClient do
  let(:valid_zone_id) { 'abc1234' }
  let(:valid_org_id) { 'def5678' }
  let(:valid_user_id) { 'someuserid' }
  let(:valid_user_email) { 'user@example.com' }
  let(:valid_iso8601_ts) { '2016-11-11T12:00:00Z' }

  it "initializes correctly with auth_key and email" do
    CloudflareClient.new(auth_key: "auth_key", email: "foo@bar.com")
  end

  it "initializes correctly with auth_token" do
    CloudflareClient.new(auth_token: "auth_token")
  end

  it "exposes internal faraday object for additional configuration with auth_key" do
    CloudflareClient.new(auth_key: "auth_key", email: "foo@bar.com") do |client|
      expect(client).to be_a(Faraday::Connection)
    end
  end

  it "exposes internal faraday object for additional configuration with auth_token" do
    CloudflareClient.new(auth_token: "auth_token") do |client|
      expect(client).to be_a(Faraday::Connection)
    end
  end

  it "raises when missing auth_key and auth_token" do
    expect { CloudflareClient.new }.to raise_error(RuntimeError, "Missing auth_key or auth_token")
  end

  it "raises when missing auth_email and using the auth_key" do
    expect { CloudflareClient.new(auth_key: "somefakekey") }.to raise_error(RuntimeError, "missing email")
  end

  describe "authentication" do
    let(:custom_hostname_list) { create(:custom_hostname_list) }

    it "Contains Authorization header when using auth_token" do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/zoneId/custom_hostnames?direction=desc&order=ssl&page=1&per_page=50&ssl=0").
           with(
             headers: {
             'Authorization'=>'Bearer: somefakekey',
             }).
           to_return(response_body(custom_hostname_list))

      CloudflareClient::Zone::CustomHostname.new(auth_token: 'somefakekey', zone_id: 'zoneId').list
    end

    it "Contains Authorization header when using auth_token" do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/zoneId/custom_hostnames?direction=desc&order=ssl&page=1&per_page=50&ssl=0").
           with(
             headers: {
             'X-Auth-Key'=>'somefakekey',
             'X-Auth-Email'=>'somefakeemail',
             }).
           to_return(response_body(custom_hostname_list))

      CloudflareClient::Zone::CustomHostname.new(auth_key: 'somefakekey', email: 'somefakeemail', zone_id: 'zoneId').list
    end
  end

end
