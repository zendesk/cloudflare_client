# rubocop:disable LineLength
require_relative "test_helper"
require_relative "test_vars"
SingleCov.covered!

require 'zendesk_cloudflare'

describe CloudflareClient do
  def response_body(body)
    {body: body, headers: {'Content-Type': 'application/json'}}
  end
  let(:client) { CloudflareClient.new(auth_key: "somefakekey", email: "foo@bar.com") }

  it "initializes correctly" do
    CloudflareClient.new(auth_key: "auth_key", email: "foo@bar.com")
  end
  it "raises when missing auth_key" do
    e = assert_raises(RuntimeError) { CloudflareClient.new }
    e.message.must_equal("Missing auth_key")
  end
  it "raises when missing auth_email" do
    e = assert_raises(RuntimeError) { CloudflareClient.new(auth_key: "somefakekey") }
    e.message.must_equal("missing email")
  end

  around do |test|
    test&.call
  end

  describe "zone operations" do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:put, "https://api.cloudflare.com/client/v4/zones/1234abcd/activation_check").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones?page=1&per_page=50").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones?name=testzonename.com&page=1&per_page=50").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/1234abc").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/shouldfail").
        to_return(response_body(FAILED_ZONE_QUERY).merge(status: 400))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/abc1234").
        to_return(response_body(SUCCESSFULL_ZONE_EDIT))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/abc1234").
        to_return(response_body(SUCCESSFULL_ZONE_DELETE))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/abc1234/purge_cache").
        to_return(response_body(SUCCESSFULL_ZONE_CACHE_PURGE))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/settings").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/settings/always_online").
        to_return(response_body(SUCCESSFULL_ZONE_QUERY))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/abc1234/settings").
        to_return(response_body(SUCCESSFULL_ZONE_EDIT))
    end
    it "creates a zone" do
      client.create_zone(name: 'testzone.com', organization: {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'}).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "fails to create a zone when missing a name" do
      e = assert_raises(RuntimeError) { client.create_zone(organization: { id: 'thisismyorgid', name: 'fish barrel and a smoking gun' }) }
      e.message.must_equal("Zone name required")
    end
    it "fails to create a zone when missing org data" do
      e = assert_raises(RuntimeError) { client.create_zone(name: 'foobar.com') }
      e.message.must_equal("Organization information required")
    end
    it "fails to delete a zone" do
      e = assert_raises(RuntimeError) { client.delete_zone }
      e.message.must_equal("zone_id required")
    end
    it "deletes a zone" do
      client.delete_zone(zone_id: "abc1234").must_equal(JSON.parse(SUCCESSFULL_ZONE_DELETE))
    end
    it "requests zone activcation check succeedes" do
      client.zone_activation_check(zone_id: '1234abcd')
    end
    it "requests zone activcation check fails" do
      e = assert_raises(RuntimeError) { client.zone_activation_check }
      e.message.must_equal("zone_id required")
    end
    it "lists all zones" do
      client.list_zones.must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "searches for a single zone" do
      client.list_zones(name: "testzonename.com").must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "returns details for a single zone" do
      client.zone_details(zone_id: "1234abc").must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "fails when getting details for a non-existent zone" do
      e = assert_raises(RuntimeError) { client.zone_details(zone_id: "shouldfail") }
      e.message.must_include("identifier is invalid")
    end
    it "fails to edit an existing zone" do
      e = assert_raises(RuntimeError) { client.edit_zone }
      e.message.must_equal("zone_id required")
    end
    it "edits and existing zone" do
      client.edit_zone(zone_id: 'abc1234', vanity_name_servers: ['ns1.foo.com', 'ns2.foo.com']).
        dig("result", "name_servers").must_equal(["ns1.foo.com", "ns2.foo.com"])
    end
    it "fails to purge the cache on a zone" do
      e = assert_raises(RuntimeError) { client.purge_zone_cache(zone_id: 'abc1234') }
      e.message.must_include("specify a combination tags[], files[] or purge_everything")
    end
    it "succeedes in purging the entire cache on a zone" do
      client.purge_zone_cache(zone_id: 'abc1234', purge_everything: true).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_CACHE_PURGE))
    end
    it "succeedes in purging a file from cache on a zone" do
      client.purge_zone_cache(zone_id: 'abc1234', files: ['/some_random_file']).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_CACHE_PURGE))
    end
    it "succeedes in purging a tag from cache on a zone" do
      client.purge_zone_cache(zone_id: 'abc1234', tags: ['tag-to-purge']).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_CACHE_PURGE))
    end
    it "fails to get all settings for a zone " do
      e = assert_raises(RuntimeError) { client.zone_settings }
      e.message.must_equal("zone_id required")
    end
    it "gets all settings for a zone" do
      client.zone_settings(zone_id: 'abc1234').must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "fails to get settings when missing a zone_id" do
      e = assert_raises(RuntimeError) { client.zone_setting(name: "always_online") }
      e.message.must_equal("zone_id required")
    end
    it "fails when trying to get an invalid setting" do
      e = assert_raises(RuntimeError) { client.zone_setting(zone_id: 'abc1234', name: "foobar") }
      e.message.must_equal("setting_name not valid")
    end
    it "gets a setting for a zone" do
      client.zone_setting(zone_id: 'abc1234', name: "always_online")
    end
    it "fails to update a zone setting when missing zone_id" do
      e = assert_raises(RuntimeError) { client.update_zone_settings }
      e.message.must_equal("zone_id required")
    end
    it "fails to update a zone setting when settings are invalid" do
      e = assert_raises(RuntimeError) { client.update_zone_settings(zone_id: "abc1234", settings: [{name: 'not_a_valid_setting', value: "yes"}]) }
      e.message.must_equal("setting_name \"not_a_valid_setting\" not valid")
    end
    it "updates a zone's setting" do
      client.update_zone_settings(zone_id: "abc1234", settings: [{name: 'always_online', value: "yes"}])
    end
  end

  describe "dns opersions" do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/abc1234/dns_records").
        to_return(response_body(SUCCESSFULL_DNS_CREATE))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/dns_records?content=192.168.1.1&name=foobar.com&order=type&page=1&per_page=50").
        to_return(response_body(SUCCESSFULL_DNS_QUERY))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/dns_records/somebigid").
        to_return(response_body(SUCCESSFULL_DNS_QUERY))
      stub_request(:put, "https://api.cloudflare.com/client/v4/zones/abc1234/dns_records/somebigid").
        to_return(response_body(SUCCESSFULL_DNS_UPDATE))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/abc1234/dns_records/somebigid").
        to_return(response_body(SUCCESSFULL_DNS_DELETE))
    end

    it "fails to create a dns record because of missing params" do
      e = assert_raises(RuntimeError) { client.create_dns_record(zone_id: "abc1234") }
      e.message.must_equal("Must specificy zone_id, name, type, and content")
    end
    it "creates a dns record" do
      client.create_dns_record(zone_id: 'abc1234', name: 'foobar.com', type: 'CNAME', content: '192.168.1.1').
        must_equal(JSON.parse(SUCCESSFULL_DNS_CREATE))
    end
    it "fails to list dns records" do
      e = assert_raises(RuntimeError) { client.dns_records }
      e.message.must_equal("zone_id required")
    end
    it "list dns records" do
      client.dns_records(zone_id: "abc1234", name: "foobar.com", content: "192.168.1.1").
        must_equal(JSON.parse(SUCCESSFULL_DNS_QUERY))
    end
    it "fails to list a specific dns record" do
      e = assert_raises(RuntimeError) { client.dns_record }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.dns_record(zone_id: 'abc1234') }
      e.message.must_equal("dns record id required")
    end
    it "returns a specfic dns record" do
      client.dns_record(zone_id: 'abc1234', id: 'somebigid').
        must_equal(JSON.parse(SUCCESSFULL_DNS_QUERY))
    end
    it "fails to update a record" do
      e = assert_raises(RuntimeError) { client.update_dns_record }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.update_dns_record(zone_id: 'abc1234') }
      e.message.must_equal("id required")
      e = assert_raises(RuntimeError) { client.update_dns_record(zone_id: 'abc1234', id: 'somebigid') }
      e.message.must_equal("must suply type, name, and content")
    end
    it "updates a dns record" do
      client.update_dns_record(zone_id: 'abc1234', id: 'somebigid', type: 'CNAME', name: 'foobar', content: '10.1.1.1').
        must_equal(JSON.parse(SUCCESSFULL_DNS_UPDATE))
    end
    it "fails to delete a dns record" do
      e = assert_raises(RuntimeError) { client.delete_dns_record }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.delete_dns_record(zone_id: 'abc1234') }
      e.message.must_equal("id required")
    end
    it "deletes a dns record" do
      client.delete_dns_record(zone_id: 'abc1234', id: 'somebigid').
        must_equal(JSON.parse(SUCCESSFULL_DNS_DELETE))
    end
  end

  describe "railgun operations" do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/railguns").
        to_return(response_body(SUCCESSFULL_RAILGUN_LIST))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/railguns/e928d310693a83094309acf9ead50448").
        to_return(response_body(SUCCESSFULL_RAILGUN_DETAILS))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/railguns/e928d310693a83094309acf9ead50448/diagnose").
        to_return(response_body(SUCCESSFULL_RAILGUN_DIAG))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/abc1234/railguns/e928d310693a83094309acf9ead50448").
        to_return(response_body(SUCCESSFULL_RAILGUN_UPDATE))
    end

    it "fails to list railguns" do
      e = assert_raises(RuntimeError) { client.available_railguns }
      e.message.must_equal("zone_id required")
    end
    it "lists railguns" do
      client.available_railguns(zone_id: 'abc1234').must_equal(JSON.parse(SUCCESSFULL_RAILGUN_LIST))
    end
    it "fails to get railguns details" do
      e = assert_raises(RuntimeError) { client.railgun_details }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.railgun_details(zone_id: 'abc1234') }
      e.message.must_equal("railgun id required")
    end
    it "railguns details" do
      client.railgun_details(zone_id: 'abc1234', id: 'e928d310693a83094309acf9ead50448').
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_DETAILS))
    end
    it "fails to test a railgun connection" do
      e = assert_raises(RuntimeError) { client.test_railgun_connection }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.test_railgun_connection(zone_id: 'abc1234') }
      e.message.must_equal('railgun id required')
    end
    it "tests railgun connection" do
      client.test_railgun_connection(zone_id: 'abc1234', id: 'e928d310693a83094309acf9ead50448').
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_DIAG))
    end
    it "fails to connect/disconnect a railgun" do
      e = assert_raises(RuntimeError) { client.connect_railgun }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.connect_railgun(zone_id: 'abc1234') }
      e.message.must_equal('railgun id required')
      e = assert_raises(RuntimeError) { client.connect_railgun(zone_id: 'abc1234', id: 'e928d310693a83094309acf9ead50448') }
      e.message.must_equal('connected must be true or false')
      client.connect_railgun(zone_id: 'abc1234', id: 'e928d310693a83094309acf9ead50448', connected: true).
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_UPDATE))
    end
  end

  describe "zone analytics" do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/analytics/dashboard").
        to_return(response_body(SUCCESSFULL_ZONE_ANALYTICS_DASHBOARD))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/analytics/dashboard").
        to_return(response_body(SUCCESSFULL_ZONE_ANALYTICS_DASHBOARD))
    end

    it "fails to return zone analytics dashboard" do
        e = assert_raises(RuntimeError) { client.zone_analytics_dashboard }
        e.message.must_equal('zone_id required')
    end
    it "returns zone analytics dashboard" do
      client.zone_analytics_dashboard(zone_id: 'abc1234').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_ANALYTICS_DASHBOARD))
    end
    it "fails to return colo analytics" do
        e = assert_raises(RuntimeError) { client.colo_analytics }
        e.message.must_equal('zone_id required')
        e = assert_raises(RuntimeError) { client.colo_analytics(zone_id: 'abc1234', since_ts: 'blah') }
        e.message.must_equal('since_ts must be a valid timestamp')
        e = assert_raises(RuntimeError) { client.colo_analytics(zone_id: 'abc1234', since_ts: '2015-01-01T12:23:00Z', until_ts: 'blah') }
        e.message.must_equal('until_ts must be a valid timestamp')
        client.colo_analytics(zone_id: 'abc1234', since_ts: '2015-01-01T12:23:00Z', until_ts: '2015-02-01T12:23:00Z')
    end
  end
end
