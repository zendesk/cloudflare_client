# rubocop:disable LineLength
require_relative "test_helper"
require_relative "fixtures/stub_api_responses.rb"
SingleCov.covered!

require 'zendesk_cloudflare'

describe CloudflareClient do
  def response_body(body)
    {body: body, headers: {'Content-Type': 'application/json'}}
  end
  let(:client) { CloudflareClient.new(auth_key: "somefakekey", email: "foo@bar.com") }
  let(:valid_zone_id) { 'abc1234' }
  let(:valid_org_id) { 'def5678' }
  let(:valid_user_id) { 'someuserid' }
  let(:valid_user_email) { 'user@example.com' }

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
      e = assert_raises(ArgumentError) { client.create_zone(organization: { id: 'thisismyorgid', name: 'fish barrel and a smoking gun' }) }
      e.message.must_equal("missing keyword: name")
      e = assert_raises(RuntimeError) { client.create_zone(name: nil, organization: { id: 'thisismyorgid', name: 'fish barrel and a smoking gun' }) }
      e.message.must_equal("Zone name required")
    end
    it "fails to delete a zone" do
      e = assert_raises(ArgumentError) { client.delete_zone }
      e.message.must_equal("missing keyword: zone_id")
      e = assert_raises(RuntimeError) { client.delete_zone(zone_id: nil) }
      e.message.must_equal("zone_id required")
    end
    it "deletes a zone" do
      client.delete_zone(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_ZONE_DELETE))
    end
    it "fails to request a zone activation check" do
      e = assert_raises(ArgumentError) { client.zone_activation_check }
      e.message.must_equal("missing keyword: zone_id")
      e = assert_raises(RuntimeError) { client.zone_activation_check(zone_id: nil) }
      e.message.must_equal("zone_id required")
    end
    it "requests zone activcation check succeedes" do
      client.zone_activation_check(zone_id: '1234abcd')
    end
    it "lists all zones" do
      client.zones.must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "lists zones with a given name" do
      client.zones(name: "testzonename.com").must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "fails lists zones with an invalid status" do
      e = assert_raises(RuntimeError) { client.zones(status: "foobar") }
      e.message.must_equal('status must be one of ["active", "pending", "initializing", "moved", "deleted", "deactivated", "read only"]')
    end
    it "lists zones with a given status" do
      client.zones(status: "active").must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "it fails to get an existing zone" do
      e = assert_raises(ArgumentError) { client.zone }
      e.message.must_include("missing keyword: zone_id")
      e = assert_raises(RuntimeError) { client.zone(zone_id: nil) }
      e.message.must_equal("zone_id required")
    end
    it "returns details for a single zone" do
      client.zone(zone_id: "1234abc").must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "fails to edit an existing zone" do
      e = assert_raises(ArgumentError) { client.edit_zone }
      e.message.must_equal("missing keyword: zone_id")
      e = assert_raises(RuntimeError) { client.edit_zone(zone_id: nil) }
      e.message.must_equal("zone_id required")
    end
    it "edits and existing zone" do
      client.edit_zone(zone_id: valid_zone_id, vanity_name_servers: ['ns1.foo.com', 'ns2.foo.com']).
        dig("result", "name_servers").must_equal(["ns1.foo.com", "ns2.foo.com"])
    end
    it "fails to purge the cache on a zone" do
      e = assert_raises(ArgumentError) { client.purge_zone_cache }
      e.message.must_include("missing keyword: zone_id")
      e = assert_raises(RuntimeError) { client.purge_zone_cache(zone_id: nil) }
      e.message.must_include("zone_id required")
      e = assert_raises(RuntimeError) { client.purge_zone_cache(zone_id: valid_zone_id) }
      e.message.must_include("specify a combination tags[], files[] or purge_everything")
    end
    it "succeedes in purging the entire cache on a zone" do
      client.purge_zone_cache(zone_id: valid_zone_id, purge_everything: true).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_CACHE_PURGE))
    end
    it "succeedes in purging a file from cache on a zone" do
      client.purge_zone_cache(zone_id: valid_zone_id, files: ['/some_random_file']).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_CACHE_PURGE))
    end
    it "succeedes in purging a tag from cache on a zone" do
      client.purge_zone_cache(zone_id: valid_zone_id, tags: ['tag-to-purge']).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_CACHE_PURGE))
    end
    it "fails to get all settings for a zone " do
      e = assert_raises(ArgumentError) { client.zone_settings }
      e.message.must_equal("missing keyword: zone_id")
      e = assert_raises(RuntimeError) { client.zone_settings(zone_id: nil) }
      e.message.must_equal("zone_id required")
    end
    it "gets all settings for a zone" do
      client.zone_settings(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_ZONE_QUERY))
    end
    it "fails to get settings for a zone" do
      e = assert_raises(ArgumentError) { client.zone_setting }
      e.message.must_equal("missing keywords: zone_id, name")
      e = assert_raises(RuntimeError) { client.zone_setting(zone_id: nil, name: 'response_buffering') }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.zone_setting(zone_id: valid_zone_id, name: "foobar") }
      e.message.must_equal("setting_name not valid")
    end
    it "gets a setting for a zone" do
      client.zone_setting(zone_id: valid_zone_id, name: "always_online")
    end
    it "fails to update zone setting" do
      e = assert_raises(ArgumentError) { client.update_zone_settings }
      e.message.must_equal("missing keyword: zone_id")
      e = assert_raises(RuntimeError) { client.update_zone_settings(zone_id: nil) }
      e.message.must_equal("zone_id required")
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

    it "fails to create a dns record" do
      e = assert_raises(ArgumentError) { client.create_dns_record() }
      e.message.must_equal("missing keywords: zone_id, name, type, content")
      e = assert_raises(RuntimeError) { client.create_dns_record(zone_id: "abc1234", name: 'blah', type: 'foo', content: 'content') }
      e.message.must_equal('type must be one of ["A", "AAAA", "CNAME", "TXT", "SRV", "LOC", "MX", "NS", "SPF", "read only"]')
    end
    it "creates a dns record" do
      client.create_dns_record(zone_id: valid_zone_id, name: 'foobar.com', type: 'CNAME', content: '192.168.1.1').
        must_equal(JSON.parse(SUCCESSFULL_DNS_CREATE))
    end
    it "fails to list dns records" do
      e = assert_raises(ArgumentError) { client.dns_records }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.dns_records(zone_id: nil) }
      e.message.must_equal("zone_id required")
    end
    it "list dns records" do
      client.dns_records(zone_id: "abc1234", name: "foobar.com", content: "192.168.1.1").
        must_equal(JSON.parse(SUCCESSFULL_DNS_QUERY))
    end
    it "fails to list a specific dns record" do
      e = assert_raises(ArgumentError) { client.dns_record }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.dns_record(zone_id: nil, id: 'foo') }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.dns_record(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal("dns record id required")
    end
    it "returns a specfic dns record" do
      client.dns_record(zone_id: valid_zone_id, id: 'somebigid').
        must_equal(JSON.parse(SUCCESSFULL_DNS_QUERY))
    end
    it "fails to update a record" do
      e = assert_raises(ArgumentError) { client.update_dns_record }
      e.message.must_equal('missing keywords: zone_id, id, type, name, content')

      e = assert_raises(RuntimeError) { client.update_dns_record(zone_id: nil, id: 'foo', name: 'foo', type: 'foo', content: 'foo') }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.update_dns_record(zone_id: valid_zone_id, id: nil, name: 'foo', type: 'foo', content: 'foo') }
      e.message.must_equal('dns record id required')

    end
    it "updates a dns record" do
      client.update_dns_record(zone_id: valid_zone_id, id: 'somebigid', type: 'CNAME', name: 'foobar', content: '10.1.1.1').
        must_equal(JSON.parse(SUCCESSFULL_DNS_UPDATE))
    end
    it "fails to delete a dns record" do
      e = assert_raises(ArgumentError) { client.delete_dns_record }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.delete_dns_record(zone_id: nil, id: 'foo') }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.delete_dns_record(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal("id required")
    end
    it "deletes a dns record" do
      client.delete_dns_record(zone_id: valid_zone_id, id: 'somebigid').
        must_equal(JSON.parse(SUCCESSFULL_DNS_DELETE))
    end
  end

  describe "railgun connection operations" do
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

    it "fails to list railgun connection" do
      e = assert_raises(ArgumentError) { client.railgun_connections }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.railgun_connections(zone_id: nil) }
      e.message.must_equal("zone_id required")
    end
    it "lists railguns" do
      client.railgun_connections(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_RAILGUN_LIST))
    end
    it "fails to get railgun connection details" do
      e = assert_raises(ArgumentError) { client.railgun_connection }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.railgun_connection(zone_id: nil, id: 'foo') }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.railgun_connection(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal("railgun id required", id: nil)
    end
    it "railguns connection details" do
      client.railgun_connection(zone_id: valid_zone_id, id: 'e928d310693a83094309acf9ead50448').
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_DETAILS))
    end
    it "fails to test a railgun connection" do
      e = assert_raises(ArgumentError) { client.test_railgun_connection }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.test_railgun_connection(zone_id: nil, id: 'foo') }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.test_railgun_connection(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('railgun id required')
    end
    it "tests railgun connection" do
      client.test_railgun_connection(zone_id: valid_zone_id, id: 'e928d310693a83094309acf9ead50448').
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_DIAG))
    end
    it "fails to connect/disconnect a railgun" do
      e = assert_raises(ArgumentError) { client.connect_railgun }
      e.message.must_equal('missing keywords: zone_id, id, connected')
      e = assert_raises(RuntimeError) { client.connect_railgun(zone_id: nil, id: 'foo', connected: true) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.connect_railgun(zone_id: valid_zone_id, id: nil, connected: true) }
      e.message.must_equal('railgun id required')
      e = assert_raises(RuntimeError) { client.connect_railgun(zone_id: valid_zone_id, id: 'e928d310693a83094309acf9ead50448', connected: nil) }
      e.message.must_equal('connected must be true or false')
    end
    it "connects a railgun" do
      client.connect_railgun(zone_id: valid_zone_id, id: 'e928d310693a83094309acf9ead50448', connected: true).
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_UPDATE))
      client.connect_railgun(zone_id: valid_zone_id, id: 'e928d310693a83094309acf9ead50448', connected: false).
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_UPDATE))
    end
  end

  describe "zone analytics" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/analytics/dashboard').
        to_return(response_body(SUCCESSFULL_ZONE_ANALYTICS_DASHBOARD))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/analytics/dashboard').
        to_return(response_body(SUCCESSFULL_ZONE_ANALYTICS_DASHBOARD))
    end

    it "fails to return zone analytics dashboard" do
        e = assert_raises(ArgumentError) { client.zone_analytics_dashboard }
        e.message.must_equal('missing keyword: zone_id')
        e = assert_raises(RuntimeError) { client.zone_analytics_dashboard(zone_id: nil) }
        e.message.must_equal('zone_id required')
    end
    it "returns zone analytics dashboard" do
      client.zone_analytics_dashboard(zone_id: valid_zone_id).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_ANALYTICS_DASHBOARD))
    end
    it "fails to return colo analytics" do
        e = assert_raises(ArgumentError) { client.colo_analytics }
        e.message.must_equal('missing keyword: zone_id')
        e = assert_raises(RuntimeError) { client.colo_analytics(zone_id: nil) }
        e.message.must_equal('zone_id required')
        e = assert_raises(RuntimeError) { client.colo_analytics(zone_id: valid_zone_id, since_ts: 'blah') }
        e.message.must_equal('since_ts must be a valid timestamp')
        e = assert_raises(RuntimeError) { client.colo_analytics(zone_id: valid_zone_id, since_ts: '2015-01-01T12:23:00Z', until_ts: 'blah') }
        e.message.must_equal('until_ts must be a valid timestamp')
        client.colo_analytics(zone_id: valid_zone_id, since_ts: '2015-01-01T12:23:00Z', until_ts: '2015-02-01T12:23:00Z')
    end
  end

  describe "dns analytics" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/dns_analytics/report').
        to_return(response_body(SUCCESSFULL_DNS_ANALYTICS_TABLE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/dns_analytics/report/bytime?limit=100&since=2015-01-01T12:23:00Z&time_delta=hour&until=2017-01-01T12:23:00Z').
        to_return(response_body(SUCCESSFULL_DNS_ANALYTICS_BY_TIME))
    end
    it "fails to return dns_analytics table" do
      e = assert_raises(ArgumentError) { client.dns_analytics_table }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.dns_analytics_table(zone_id: nil) }
      e.message.must_equal('zone_id required')
    end
    it "returns dns analytics" do
      client.dns_analytics_table(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_DNS_ANALYTICS_TABLE))
    end
    it "fails to return dns bytime analytics" do
      e = assert_raises(ArgumentError) { client.dns_analytics_bytime}
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.dns_analytics_bytime(zone_id: nil)}
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.dns_analytics_bytime(zone_id: valid_zone_id, since_ts: 'foo')}
      e.message.must_equal('since_ts must be a valid timestamp')
      e = assert_raises(RuntimeError) { client.dns_analytics_bytime(zone_id: valid_zone_id, since_ts: '2015-01-01T12:23:00Z', until_ts: 'foo')}
      e.message.must_equal('until_ts must be a valid timestamp')
      client.dns_analytics_bytime(zone_id: valid_zone_id, since_ts: '2015-01-01T12:23:00Z', until_ts: '2017-01-01T12:23:00Z').
        must_equal(JSON.parse(SUCCESSFULL_DNS_ANALYTICS_BY_TIME))
    end
  end

  describe "railgun api" do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/railguns').
        to_return(response_body(SUCCESSFULL_RAILGUN_CREATION))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/railguns?direction=desc&page=1&per_page=50').
        to_return(response_body(SUCCESSFULL_RAILGUN_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/railguns/somerailgunid').
        to_return(response_body(SUCCESSFULL_RAILGUN_DETAILS))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/railguns/somerailgunid/zones').
        to_return(response_body(SUCCESSFULL_RAILGUN_ZONES))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/railguns/abc1234').
        to_return(response_body(SUCCESSFULL_RAILGUN_STATUS))
      stub_request(:delete, 'https://api.cloudflare.com/client/v4/railguns/abc1234').
        to_return(response_body(SUCCESSFULL_RAILGUN_DELETE))
    end

    it "fails to create a railgun with missing name" do
      e = assert_raises(ArgumentError) { client.create_railgun }
      e.message.must_equal('missing keyword: name')
      e = assert_raises(RuntimeError) { client.create_railgun(name: nil) }
      e.message.must_equal("Railgun name cannot be nil")
    end
    it "creates a railgun" do
      client.create_railgun(name: 'foobar').
        must_equal(JSON.parse(SUCCESSFULL_RAILGUN_CREATION))
    end
    it "fails to lists all railguns" do
      e = assert_raises(RuntimeError) { client.railguns(direction: 'foo')}
      e.message.must_equal('direction must be either desc | asc')
    end
    it "lists all railguns" do
      client.railguns.must_equal(JSON.parse(SUCCESSFULL_RAILGUN_LIST))
    end
    it "fails to get railgun details" do
      e = assert_raises(ArgumentError) { client.railgun }
      e.message.must_equal('missing keyword: id')
      e = assert_raises(RuntimeError) { client.railgun(id: nil) }
      e.message.must_equal('must provide the id of the railgun')
    end
    it "get a railgun's details" do
      client.railgun(id: 'somerailgunid').must_equal(JSON.parse(SUCCESSFULL_RAILGUN_DETAILS))
    end
    it "fails to get zones for a railgun" do
      e = assert_raises(ArgumentError) { client.railgun_zones}
      e.message.must_equal('missing keyword: id')
      e = assert_raises(RuntimeError) { client.railgun_zones(id: nil)}
      e.message.must_equal('must provide the id of the railgun')
    end
    it "gets zones connected to a railgun" do
      client.railgun_zones(id: 'somerailgunid').must_equal(JSON.parse(SUCCESSFULL_RAILGUN_ZONES))
    end
    it "fails to change the status of a railgun" do
      e = assert_raises(ArgumentError) { client.railgun_enabled }
      e.message.must_equal('missing keywords: id, enabled')
      e = assert_raises(RuntimeError) { client.railgun_enabled(id: nil, enabled: true) }
      e.message.must_equal('must provide the id of the railgun')
      e = assert_raises(RuntimeError) { client.railgun_enabled(id: valid_zone_id, enabled: 'foobar') }
      e.message.must_equal('enabled must be true | false')
    end
    it "enables a railgun" do
      client.railgun_enabled(id: valid_zone_id, enabled: true).must_equal(JSON.parse(SUCCESSFULL_RAILGUN_STATUS))
    end
    it "fails to delete a railgun" do
      e = assert_raises(ArgumentError) { client.delete_railgun }
      e.message.must_equal('missing keyword: id')
      e = assert_raises(RuntimeError) { client.delete_railgun(id: nil) }
      e.message.must_equal('must provide the id of the railgun')
    end
    it "deletes a railgun" do
      client.delete_railgun(id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_RAILGUN_DELETE))
    end
  end

  describe "custom_pages" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_pages').
        to_return(response_body(SUCCESSFULL_CUSTOM_PAGES))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_pages/footothebar').
        to_return(response_body(SUCCESSFULL_CUSTOM_PAGE_DETAIL))
      stub_request(:put, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_pages/footothebar').
        to_return(response_body(SUCCESSFULL_CUSTOM_PAGE_UPDATE))
    end

    it "fails to list custom pages" do
      e = assert_raises(ArgumentError) { client.custom_pages }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.custom_pages(zone_id: nil) }
      e.message.must_equal('zone_id required')
    end
    it "lists custom pages" do
      client.custom_pages(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_CUSTOM_PAGES))
    end
    it "fails to get details for a custom page" do
      e = assert_raises(ArgumentError) { client.custom_page }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.custom_page(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.custom_page(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id must not be nil')
    end
    it "gets details for a custom page" do
      client.custom_page(zone_id: valid_zone_id, id: 'footothebar').must_equal(JSON.parse(SUCCESSFULL_CUSTOM_PAGE_DETAIL))
    end
    it "fails to update a custom page" do
      e = assert_raises(ArgumentError) { client.update_custom_page }
      e.message.must_equal('missing keywords: zone_id, id, url, state')
      e = assert_raises(RuntimeError) { client.update_custom_page(zone_id: nil, id: '1234', url: 'foo.bar', state: 'default') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_custom_page(zone_id: valid_zone_id, id: nil, url: 'foo.bar', state: 'default') }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_custom_page(zone_id: valid_zone_id, id: '1234', url: nil, state: 'default') }
      e.message.must_equal('url required')
      e = assert_raises(RuntimeError) { client.update_custom_page(zone_id: valid_zone_id, id: 'footothebar', url: 'http://foo.bar', state: 'whateverman') }
      e.message.must_equal('state must be either default | customized')
    end
    it "updates a custom page" do
      client.update_custom_page(zone_id: valid_zone_id, id: 'footothebar', url: 'http://foo.bar', state: 'customized').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_PAGE_UPDATE))
    end
  end

  describe "custom_ssl for a zone" do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_certificates').
        to_return(response_body(SUCCESSFULL_CUSTOM_SSL))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_certficates?direction=asc&match=all&page=1&per_page=50').
        to_return(response_body(SUCCESSFULL_CUSTOM_SSL_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_certificates/footothebar').
        to_return(response_body(SUCCESSFULL_CUSTOM_SSL_CONFIG))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_certificates/foo').
        to_return(response_body(SUCCESSFULL_CUSTOM_SSL_CONFIG_UPDATE))
      stub_request(:put, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_certificates/prioritize').
        to_return(response_body(SUCCESSFULL_CUSTOM_SSL_UPDATE_PRIORITY))
      stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_certificates/7e7b8deba8538af625850b7b2530034c').
        to_return(response_body(SUCCESSFULL_CUSTOM_SSL_DELETE))
    end

    it "fails to create custom ssl for a zone" do
      e = assert_raises(ArgumentError) { client.create_custom_ssl }
      e.message.must_equal('missing keywords: zone_id, certificate, private_key')
      e = assert_raises(RuntimeError) { client.create_custom_ssl(zone_id: nil, private_key: 'foo', certificate: 'bar') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.create_custom_ssl(zone_id: valid_zone_id, private_key: nil, certificate: 'bar') }
      e.message.must_equal('private_key required')
      e = assert_raises(RuntimeError) { client.create_custom_ssl(zone_id: valid_zone_id, private_key: 'foo', certificate: nil) }
      e.message.must_equal('certificate required')
      e = assert_raises(RuntimeError) { client.create_custom_ssl(zone_id: valid_zone_id, certificate: 'foo', private_key: 'bar', bundle_method: 'foobar') }
      e.message.must_equal('valid bundle methods are ["ubiquitous", "optimal", "force"]')
    end
    it "creates custom ssl for a zone" do
      client.create_custom_ssl(zone_id: valid_zone_id, certificate: 'blahblah', private_key: 'pkstring', bundle_method: 'force').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_SSL))
    end
    it "fails to list all custom ssl configurations" do
      e = assert_raises(ArgumentError) { client.ssl_configurations }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.ssl_configurations(zone_id: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.ssl_configurations(zone_id: valid_zone_id, order: 'foo') }
      e.message.must_equal('order must be one of ["status", "issuer", "priority", "expires_on"]')
      e = assert_raises(RuntimeError) { client.ssl_configurations(zone_id: valid_zone_id, order: 'status', direction: 'foo') }
      e.message.must_equal('direction must be asc || desc')
      e = assert_raises(RuntimeError) { client.ssl_configurations(zone_id: valid_zone_id, order: 'status', direction: 'asc', match: 'foo') }
      e.message.must_equal('match must be all || any')
      e = assert_raises(RuntimeError) { client.ssl_configurations(zone_id: valid_zone_id, order: 'status', direction: 'desc', match: 'foo') }
      e.message.must_equal('match must be all || any')
    end
    it "lists all custom ssl configurations" do
      client.ssl_configurations(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_CUSTOM_SSL_LIST))
    end
    it "fails to get details for a custom configuration" do
      e = assert_raises(ArgumentError) { client.ssl_configuration }
      e.message.must_equal('missing keywords: zone_id, configuration_id')
      e = assert_raises(RuntimeError) { client.ssl_configuration(zone_id: nil, configuration_id: 'foo') }
      e.message.must_equal("zone_id required")
      e = assert_raises(RuntimeError) { client.ssl_configuration(zone_id: valid_zone_id, configuration_id: nil) }
      e.message.must_equal("ssl configuration id required")
    end
    it "returns details of a custom ssl configuration" do
      client.ssl_configuration(zone_id: valid_zone_id, configuration_id: 'footothebar').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_SSL_CONFIG))
    end
    it "fails to update a custom ssl config" do
      e = assert_raises(ArgumentError) { client.update_ssl_configuration }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.update_ssl_configuration(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_ssl_configuration(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_ssl_configuration(zone_id: valid_zone_id, id: 'foo', certificate: 'here', private_key: 'found', bundle_method: 'foo') }
      e.message.must_equal('valid bundle methods are ["ubiquitous", "optimal", "force"]')
    end
    it "updates a custom ssl config" do
      client.update_ssl_configuration(zone_id: valid_zone_id, id: 'foo', certificate: 'here', private_key: 'found', bundle_method: 'force').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_SSL_CONFIG_UPDATE))
    end
    it "fails to prioritize_ssl_configurations" do
      e = assert_raises(ArgumentError) { client.prioritize_ssl_configurations }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.prioritize_ssl_configurations(zone_id: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.prioritize_ssl_configurations(zone_id: valid_zone_id) }
      e.message.must_equal('must provide an array of certifiates and priorities')
    end
    it "updates the prioritiy of custom ssl certificates" do
      client.prioritize_ssl_configurations(zone_id: valid_zone_id, data: [{id: 'abcd', priority: 12}, {id: 'foo', priority: 1}]).
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_SSL_UPDATE_PRIORITY))
    end
    it "fails to delete a custom ssl configuration" do
      e = assert_raises(ArgumentError) { client.delete_ssl_configuration }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.delete_ssl_configuration(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.delete_ssl_configuration(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "deletes a custom ssl configuration"  do
      client.delete_ssl_configuration(zone_id: valid_zone_id, id: '7e7b8deba8538af625850b7b2530034c').
          must_equal(JSON.parse(SUCCESSFULL_CUSTOM_SSL_DELETE))
    end
  end

  describe "custom_hostnames" do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_hostnames').
        to_return(response_body(SUCCESSFULL_CUSTOM_HOSTNAME_CREATE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_hostnames?direction=desc&hostname=foobar&order=ssl&page=1&per_page=50&ssl=0').
        to_return(response_body(SUCCESSFULL_CUSTOM_HOSTNAME_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_hostnames?direction=desc&id=12345&order=ssl&page=1&per_page=50&ssl=0').
        to_return(response_body(SUCCESSFULL_CUSTOM_HOSTNAME_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_hostnames?direction=desc&order=ssl&page=1&per_page=50&ssl=0').
        to_return(response_body(SUCCESSFULL_CUSTOM_HOSTNAME_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_hostnames/someid').
        to_return(response_body(SUCCESSFULL_CUSTOM_HOSTNAME_DETAIL))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_hostnames/foo').
        to_return(response_body(SUCCESSFULL_CUSTOM_HOSTNAME_UPDATE))
      stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/custom_hostnames/foo').
        to_return(response_body(SUCCESSFULL_CUSTOM_HOSTNAME_DELETE))
    end

    it "fails to create a custom_hostname" do
      e = assert_raises(ArgumentError) { client.create_custom_hostname }
      e.message.must_equal('missing keywords: zone_id, hostname')
      e = assert_raises(RuntimeError) { client.create_custom_hostname(zone_id: nil, hostname: 'petethecat') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.create_custom_hostname(zone_id: valid_zone_id, hostname: nil) }
      e.message.must_equal('hostname required')
      e = assert_raises(RuntimeError) { client.create_custom_hostname(zone_id: valid_zone_id, hostname: 'footothebar', method: 'snail') }
      e.message.must_equal('method must be one of ["http", "email", "cname"]')
      e = assert_raises(RuntimeError) { client.create_custom_hostname(zone_id: valid_zone_id, hostname: 'footothebar', type: 'snail') }
      e.message.must_equal('type must be either dv or read only')
    end
    it "creates a custom hostname" do
      client.create_custom_hostname(zone_id: valid_zone_id, hostname: 'somerandomhost').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_CREATE))
    end
    it "fails to list custom hostnames" do
      e = assert_raises(ArgumentError) { client.custom_hostnames }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.custom_hostnames(zone_id: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.custom_hostnames(zone_id: valid_zone_id, hostname: 'foo', id: 'bar') }
      e.message.must_equal('cannot use hostname and id')
    end
    it "lists custom_hostnames" do
      client.custom_hostnames(zone_id: valid_zone_id, hostname: 'foobar').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_LIST))
      client.custom_hostnames(zone_id: valid_zone_id, id: '12345').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_LIST))
      client.custom_hostnames(zone_id: valid_zone_id).
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_LIST))
    end
    it "fails to get details for a custom hostname" do
      e = assert_raises(ArgumentError) { client.custom_hostname }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.custom_hostname(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.custom_hostname(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "returns details for a custom hostname" do
      client.custom_hostname(zone_id: valid_zone_id, id: 'someid').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_DETAIL))
    end
    it "fails to update a custom_hostname" do
      e = assert_raises(ArgumentError) { client.update_custom_hostname }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.update_custom_hostname(zone_id: nil, id: 'foo', method: 'bar', type: 'cat') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_custom_hostname(zone_id: valid_zone_id, id: nil, method: 'bar', type: 'cat') }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_custom_hostname(zone_id: valid_zone_id, id: 'foo', method: 'bar', type: 'cat') }
      e.message.must_equal('method must be one of ["http", "email", "cname"]')
      e = assert_raises(RuntimeError) { client.update_custom_hostname(zone_id: valid_zone_id, id: 'foo', method: 'http', type: 'cat') }
      e.message.must_equal('type must be one of ["read only", "dv"]')
      e = assert_raises(RuntimeError) { client.update_custom_hostname(zone_id: valid_zone_id, id: 'foo', method: 'http', type: 'dv', custom_metadata: 'bob') }
      e.message.must_equal('custom_metadata must be an object')
    end
    it "udpates a custom hostname" do
      client.update_custom_hostname(zone_id: valid_zone_id, id: 'foo', method: 'http', type: 'dv').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_UPDATE))
      client.update_custom_hostname(zone_id: valid_zone_id, id: 'foo', method: 'http', type: 'dv', custom_metadata: {origin_override: 'footothebar'}).
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_UPDATE))
    end
    it "fails to delete a custom_hostname" do
      e = assert_raises(ArgumentError) { client.delete_custom_hostname }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.delete_custom_hostname(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.delete_custom_hostname(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "deletes a custom_hostname" do
      client.delete_custom_hostname(zone_id: valid_zone_id, id: 'foo').
        must_equal(JSON.parse(SUCCESSFULL_CUSTOM_HOSTNAME_DELETE))
    end
  end

  describe "keyless ssl" do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/keyless_certificates').
        to_return(response_body(SUCCESSFULL_KEYLESS_SSL_CREATE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/keyless_certificates').
        to_return(response_body(SUCCESSFULL_KEYLESS_SSL_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zons/abc1234/keyless_certificates/4d2844d2ce78891c34d0b6c0535a291e').
        to_return(response_body(SUCCESSFULL_KEYLESS_SSL_DETAIL))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/keyless_certificates/blah').
        to_return(response_body(SUCCESSFULL_KEYLESS_SSL_UPDATE))
      stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/keyless_certificates/somekeylessid').
        to_return(response_body(SUCCESSFULL_KEYLESS_SSL_DELETE))
    end

    it "fails to create a keyless ssl config" do
      e = assert_raises(ArgumentError) { client.create_keyless_ssl_config }
      e.message.must_equal('missing keywords: zone_id, host, port, certificate')
      e = assert_raises(RuntimeError) { client.create_keyless_ssl_config(zone_id: nil, host: 'foo', port: 1234, certificate: 'bar') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.create_keyless_ssl_config(zone_id: valid_zone_id, host: nil, port: 1234, certificate: 'bar') }
      e.message.must_equal('host required')
      e = assert_raises(RuntimeError) { client.create_keyless_ssl_config(zone_id: valid_zone_id, host: 'foo', port: 1234, certificate: nil) }
      e.message.must_equal('certificate required')
      e = assert_raises(RuntimeError) { client.create_keyless_ssl_config(zone_id: valid_zone_id, host: 'foobar', port: 1234, certificate: 'cert data', bundle_method: 'foo')}
      e.message.must_equal('valid bundle methods are ["ubiquitous", "optimal", "force"]')
    end
    it "creates a keyless ssl config" do
      client.create_keyless_ssl_config(zone_id: valid_zone_id, host: 'foobar', certificate: 'cert data', port: 1245).
        must_equal(JSON.parse(SUCCESSFULL_KEYLESS_SSL_CREATE))
    end
    it "fails to list keyless_ssl_configs" do
      e = assert_raises(ArgumentError) { client.keyless_ssl_configs }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.keyless_ssl_configs(zone_id: nil) }
      e.message.must_equal('zone_id required')
    end
    it "lists all keyless ssl configs" do
      client.keyless_ssl_configs(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_KEYLESS_SSL_LIST))
    end
    it "fails to list details of a keless_ssl_config" do
      e = assert_raises(ArgumentError) { client.keyless_ssl_config }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.keyless_ssl_config(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.keyless_ssl_config(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "lists details of a keyless_ssl_config" do
      client.keyless_ssl_config(zone_id: valid_zone_id, id: '4d2844d2ce78891c34d0b6c0535a291e').
        must_equal(JSON.parse(SUCCESSFULL_KEYLESS_SSL_DETAIL))
    end
    it "fails to update a keyless_ssl_config" do
      e = assert_raises(ArgumentError) { client.update_keyless_ssl_config }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.update_keyless_ssl_config(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_keyless_ssl_config(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_keyless_ssl_config(zone_id: valid_zone_id, id: 'blah', enabled: 'foo') }
      e.message.must_equal('enabled must be true||false')
    end
    it "updates a keyless ssl config)" do
      client.update_keyless_ssl_config(zone_id: valid_zone_id, id: 'blah', enabled: true, host: 'foo.com', port: 1234).
        must_equal(JSON.parse(SUCCESSFULL_KEYLESS_SSL_UPDATE))
    end
    it "fails to delete a keyless ssl config" do
      e = assert_raises(ArgumentError) { client.delete_keyless_ssl_config }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.delete_keyless_ssl_config(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.delete_keyless_ssl_config(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "deletes a keyless ssl config" do
      client.delete_keyless_ssl_config(zone_id: valid_zone_id, id: 'somekeylessid').
        must_equal(JSON.parse(SUCCESSFULL_KEYLESS_SSL_DELETE))
    end
  end

  describe "page rules" do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/pagerules').
        to_return(response_body(SUCCESSFULL_ZONE_PAGE_RULE_CREATE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/pagerules?direction=asc&match=any&order=status&status=active').
        to_return(response_body(SUCCESSFULL_ZONE_PAGE_RULE_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/pagerules/9a7806061c88ada191ed06f989cc3dac').
        to_return(response_body(SUCCESSFULL_ZONE_PAGE_RULE_DETAIL))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/pagerules/9a7806061c88ada191ed06f989cc3dac').
        to_return(response_body(SUCCESSFULL_ZONE_PAGE_RULE_DETAIL))
      stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/pagerules/9a7806061c88ada191ed06f989cc3dac').
        to_return(response_body(SUCCESSFULL_ZONE_PAGE_RULE_DELETE))
    end

    it "fails to create a custom page rule" do
      e = assert_raises(ArgumentError) { client.create_zone_page_rule }
      e.message.must_equal('missing keywords: zone_id, targets, actions')
      e = assert_raises(RuntimeError) { client.create_zone_page_rule(zone_id: nil, targets: ['a'], actions: ['b']) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.create_zone_page_rule(zone_id: valid_zone_id, targets: 'foo', actions: ['b']) }
      e.message.must_equal('targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.create_zone_page_rule(zone_id: valid_zone_id, targets: [], actions: ['b']) }
      e.message.must_equal('targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.create_zone_page_rule(zone_id: valid_zone_id, targets: [{foo: 'bar'}], actions: 'blah' ) }
      e.message.must_equal('actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.create_zone_page_rule(zone_id: valid_zone_id, targets: [{foo: 'bar'}], actions: [] ) }
      e.message.must_equal('actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.create_zone_page_rule(zone_id: valid_zone_id, targets: [{foo: 'bar'}], actions: [{foo: 'bar'}], status: 'boo' ) }
      e.message.must_equal('status must be disabled||active')
    end
    it "creates a custom page rule" do
      client.create_zone_page_rule(zone_id: valid_zone_id, targets: [{foo: 'bar'}], actions: [{foo: 'bar'}], status: 'active' ).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_CREATE))
    end
    it "fails to list all the page rules for a zone" do
      e = assert_raises(ArgumentError) { client.zone_page_rules }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.zone_page_rules(zone_id: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.zone_page_rules(zone_id: valid_zone_id, status: 'foo') }
      e.message.must_equal('status must be either active||disabled')
      e = assert_raises(RuntimeError) { client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'foo') }
      e.message.must_equal('order must be either status||priority')
      e = assert_raises(RuntimeError) { client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'status', direction: 'foo') }
      e.message.must_equal('direction must be either asc||desc')
      e = assert_raises(RuntimeError) { client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'status', direction: 'asc', match: 'foo') }
      e.message.must_equal('match must be either any||all')
    end
    it "lists all the page rules for a zone" do
      client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'status', direction: 'asc', match: 'any').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_LIST))
    end
    it "fails to get details for a page rule" do
      e = assert_raises(ArgumentError) { client.zone_page_rule }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.zone_page_rule(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.zone_page_rule(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "gets details for a page rule" do
      client.zone_page_rule(zone_id: valid_zone_id, id: '9a7806061c88ada191ed06f989cc3dac').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_DETAIL))
    end
    it "fails to udpate a zone page rule" do
      e = assert_raises(ArgumentError) { client.update_zone_page_rule }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.update_zone_page_rule(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_zone_page_rule(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: 'foo') }
      e.message.must_equal('targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: []) }
      e.message.must_equal('targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: [{blah: 'blah'}]) }
      e.message.must_equal('actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: [{blah: 'blah'}], actions: 'foo') }
      e.message.must_equal('actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')
      e = assert_raises(RuntimeError) { client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: [{blah: 'blah'}], actions: [{blah: 'blah'}], status: 'blargh') }
      e.message.must_equal('status must be disabled||active')
    end
    it "udpates a zone page rule" do
      client.update_zone_page_rule(zone_id: valid_zone_id, id: '9a7806061c88ada191ed06f989cc3dac', targets: [{blah: 'blah'}], actions: [{blah: 'blah'}]).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_DETAIL))
    end
    it "fails to delete a zone page rule" do
      e = assert_raises(ArgumentError) { client.delete_zone_page_rule }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.delete_zone_page_rule(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.delete_zone_page_rule(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('zone page rule id required')
    end
    it "deletes a zone page rule" do
      client.delete_zone_page_rule(zone_id: valid_zone_id, id: '9a7806061c88ada191ed06f989cc3dac').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_DELETE))
    end
  end

  describe "zone rate limits" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4zones/abc1234?page=1&per_page=50').
        to_return(response_body(SUCCESSFULL_ZONE_RATE_LIMITS_LIST))
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/rate_limits').
        to_return(response_body(SUCCESSFULL_ZONE_RATE_LIMITS_CREATE))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/rate_limits/372e67954025e0ba6aaa6d586b9e0b59').
        to_return(response_body(SUCCESSFULL_ZONE_RATE_LIMITS_DETAIL))
      stub_request(:put, 'https://api.cloudflare.com/client/v4/zones/abc1234/rate_limits/372e67954025e0ba6aaa6d586b9e0b59').
        to_return(response_body(SUCCESSFULL_ZONE_RATE_LIMITS_UPDATE))
      stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/rate_limits/372e67954025e0ba6aaa6d586b9e0b59').
        to_return(response_body(SUCCESSFULL_ZONE_RATE_LIMITS_DELETE))
    end

    it "fails to list rate limits for a zone" do
      e = assert_raises(ArgumentError) { client.zone_rate_limits }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.zone_rate_limits(zone_id: nil) }
      e.message.must_equal('zone_id required')
    end
    it "lists rate limits for a zone" do
      client.zone_rate_limits(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_LIST))
    end
    it "fails to create a zone rate limit" do
      e = assert_raises(ArgumentError) { client.create_zone_rate_limit }
      e.message.must_equal('missing keywords: zone_id, match, threshold, period, action')
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: nil, match: {}, action: {}, threshold: 1, period: 2) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: 'foo', action: {}, threshold: 1, period: 2) }
      e.message.must_equal('match must be a match object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: 'foo', threshold: 1, period: 2) }
      e.message.must_equal('action must be a action object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')

      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 'foo', period: 2) }
      e.message.must_equal('threshold must be between 1 86400')
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 0, period: 2) }
      e.message.must_equal('threshold must be between 1 86400')
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 1, period: 'foo') }
      e.message.must_equal('period must be between 1 86400')
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 1, period: 0) }
      e.message.must_equal('period must be between 1 86400')
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 2, period: 1, disabled: 'foo') }
      e = assert_raises(RuntimeError) { client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 2, period: 1, disabled: 'blah') }
      e.message.must_equal('disabled must be true || false')
    end
    it "creates a zone rate limit" do
      client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 2, disabled: true, period: 30).
        must_equal(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_CREATE))
    end
    it "fails to return details for a zone rate limit" do
      e = assert_raises(ArgumentError) { client.zone_rate_limit }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.zone_rate_limit(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.zone_rate_limit(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "returns details for a zone rate limit" do
      client.zone_rate_limit(zone_id: valid_zone_id, id: '372e67954025e0ba6aaa6d586b9e0b59').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_DETAIL))
    end
    it "fails to update a zone rate limit" do
      e = assert_raises(ArgumentError) { client.update_zone_rate_limit }
      e.message.must_equal('missing keywords: zone_id, id, match, threshold, period, action')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: nil, id: nil, match: nil, threshold: nil, period: nil, action: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: valid_zone_id, id: nil, match: nil, threshold: nil, period: nil, action: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: nil, threshold: nil, period: nil, action: nil) }
      e.message.must_equal('match must be a match object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: {}, threshold: 1, period: nil, action: nil) }
      e.message.must_equal('action must be a action object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: {}, threshold: nil, period: nil, action: nil) }
      e.message.must_equal('threshold must be between 1 86400')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: {}, threshold: nil, period: nil, action: nil) }
      e.message.must_equal('threshold must be between 1 86400')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'foobar', match: {}, action: {}, threshold: 50, period: 'foo') }
      e.message.must_equal('period must be between 1 86400')
      e = assert_raises(RuntimeError) { client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'foobar', match: {}, action: {}, threshold: 50, period: 200, disabled: 'foo') }
      e.message.must_equal('disabled must be true || false')
    end
    it "updates a zone rate limit" do
      client.update_zone_rate_limit(zone_id: valid_zone_id, id: '372e67954025e0ba6aaa6d586b9e0b59', match: {}, action: {}, threshold: 50, period: 100, disabled: false, description: 'foo to the bar').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_UPDATE))
    end
    it "fails to delete a zone ratelimit" do
      e = assert_raises(ArgumentError) { client.delete_zone_rate_limit }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.delete_zone_rate_limit(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.delete_zone_rate_limit(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('zone rate limit id required')
    end
    it "deletes a zone ratelimit" do
      client.delete_zone_rate_limit(zone_id: valid_zone_id, id: '372e67954025e0ba6aaa6d586b9e0b59').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_DELETE))
    end
  end

  describe "firwall access rules" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/access_rules/rules?configuration_target=country&direction=asc&match=all&mode=block&page=1&per_page=50&scope_type=zone').
        to_return(response_body(SUCCESSFULL_FIREWALL_LIST))
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/access_rules/rules').
        to_return(response_body(SUCCESSFULL_FIREWALL_CREATE_UPDATE))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/access_rules/rules/foo').
        to_return(response_body(SUCCESSFULL_FIREWALL_CREATE_UPDATE))
      stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/access_rules/rules/foo').
        to_return(response_body(SUCCESSFULL_FIREWALL_DELETE))
    end

    it "fails to list firewall access rules" do
      e = assert_raises(ArgumentError) { client.firewall_access_rules }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.firewall_access_rules(zone_id: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.firewall_access_rules(zone_id: valid_zone_id, mode: 'foo') }
      e.message.must_equal('mode can only be one of block, challenge, whitelist')
      e = assert_raises(RuntimeError) { client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'foo') }
      e.message.must_equal('match can only be one either all || any')
      e = assert_raises(RuntimeError) { client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'all', scope_type: 'foo') }
      e.message.must_equal('scope_type can only be one of user, organization, zone')
      e = assert_raises(RuntimeError) { client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'all', scope_type: 'zone', configuration_target: 'foo') }
      e.message.must_equal('configuration_target can only be one ["ip", "ip_range", "country"]')
      e = assert_raises(RuntimeError) { client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'all', scope_type: 'zone', configuration_target: 'country', direction: 'foo') }
      e.message.must_equal('direction must be either asc || desc')
    end
    it "lists firewall access rules" do
      client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'all', scope_type: 'zone', configuration_target: 'country', direction: 'asc').
        must_equal(JSON.parse(SUCCESSFULL_FIREWALL_LIST))
    end
    it "fails to create a firewall access rule" do
      e = assert_raises(ArgumentError) { client.create_firewall_access_rule }
      e.message.must_equal('missing keywords: zone_id, mode, configuration')
      e = assert_raises(RuntimeError) { client.create_firewall_access_rule(zone_id: nil, mode: 'foo', configuration: {}) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.create_firewall_access_rule(zone_id: valid_zone_id, mode: 'foo', configuration: 'foo') }
      e.message.must_equal('mode must be one of block, challenge, whitlist')
      e = assert_raises(RuntimeError) { client.create_firewall_access_rule(zone_id: valid_zone_id, mode: 'block', configuration: 'foo') }
      e.message.must_equal('configuration must be a valid configuration object')
      e = assert_raises(RuntimeError) { client.create_firewall_access_rule(zone_id: valid_zone_id, mode: 'block', configuration: {foo: 'bar'}) }
      e.message.must_equal('configuration must contain valid a valid target and value')
      e.message.must_equal('configuration must contain valid a valid target and value')
    end
    it "creates a new firewall access rule" do
      client.create_firewall_access_rule(
        zone_id: valid_zone_id,
        mode: 'block',
        configuration: {target: 'ip', value: '10.1.1.1'}
      ).must_equal(JSON.parse(SUCCESSFULL_FIREWALL_CREATE_UPDATE))
    end
    it "fails to updates a firewall access rule" do
      e = assert_raises(ArgumentError) { client.update_firewall_access_rule }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.update_firewall_access_rule(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_firewall_access_rule(zone_id: 'foo', id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_firewall_access_rule(zone_id: 'foo', id: 'bar', mode: 'foo') }
      e.message.must_equal('mode must be one of block, challenge, whitlist')
    end
    it "updates a firewall access rule" do
      client.update_firewall_access_rule(zone_id: valid_zone_id, id: 'foo', mode: 'block', notes: 'foo to the bar').
        must_equal(JSON.parse(SUCCESSFULL_FIREWALL_CREATE_UPDATE))
    end
    it "fails to delete a firewall access rule" do
      e = assert_raises(ArgumentError) { client.delete_firewall_access_rule }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.delete_firewall_access_rule(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.delete_firewall_access_rule(zone_id: 'foo', id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.delete_firewall_access_rule(zone_id: 'foo', id: 'bar', cascade: 'cat') }
      e.message.must_equal('cascade must be one of none, basic, aggressive')
    end
    it "deletes a firewall access rule" do
      client.delete_firewall_access_rule(zone_id: valid_zone_id, id: 'foo', cascade: 'basic').
        must_equal(JSON.parse(SUCCESSFULL_FIREWALL_DELETE))
    end
  end

  describe "waf rule packages" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages?direction=asc&match=any&name=bar&order=status&page=1&per_page=50').
        to_return(response_body(SUCCESSFULL_WAF_RULE_PACKAGES_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages/foo').
        to_return(response_body(SUCCESSFULL_WAF_RULE_PACKAGES_DETAIL))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages/foo').
        to_return(response_body(SUCCESSFULL_WAF_RULE_PACKAGES_UPDATE))
    end
    it "fails to get waf rule packages" do
      e = assert_raises(ArgumentError) { client.waf_rule_packages }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.waf_rule_packages(zone_id: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.waf_rule_packages(zone_id: valid_zone_id, order: 'foo') }
      e.message.must_equal('order must be either status or name')
      e = assert_raises(RuntimeError) { client.waf_rule_packages(zone_id: valid_zone_id, order: 'status', direction: 'foo') }
      e.message.must_equal('direction must be either asc or desc')
      e = assert_raises(RuntimeError) { client.waf_rule_packages(zone_id: valid_zone_id, order: 'status', direction: 'asc', match: 'foo') }
      e.message.must_equal('match must be either all or any')
    end
    it "gets waf rule packages" do
      client.waf_rule_packages(zone_id: valid_zone_id, order: 'status', direction: 'asc', match: 'any', name: 'bar').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULE_PACKAGES_LIST))
    end
    it "fails to get package details" do
      e = assert_raises(ArgumentError) { client.waf_rule_package }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.waf_rule_package(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.waf_rule_package(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "gets a waf rule package" do
      client.waf_rule_package(zone_id: valid_zone_id, id: 'foo').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULE_PACKAGES_DETAIL))
    end
    it "fails to change the anomoly detection settings of a waf package" do
      e = assert_raises(ArgumentError) { client.change_waf_rule_anomoly_detection }
      e.message.must_equal('missing keywords: zone_id, id')
      e = assert_raises(RuntimeError) { client.change_waf_rule_anomoly_detection(zone_id: nil, id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.change_waf_rule_anomoly_detection(zone_id: valid_zone_id, id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.change_waf_rule_anomoly_detection(zone_id: valid_zone_id, id: 'foo', sensitivity: 'bar') }
      e.message.must_equal('sensitivity must be one of high, low, off')
      e = assert_raises(RuntimeError) { client.change_waf_rule_anomoly_detection(zone_id: valid_zone_id, id: 'foo', sensitivity: 'high', action_mode: 'bar') }
      e.message.must_equal('action_mode must be one of simulate, block or challenge')
    end
    it "updates a waf rule package" do
      client.change_waf_rule_anomoly_detection(zone_id: valid_zone_id, id: 'foo', sensitivity: 'high', action_mode: 'challenge').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULE_PACKAGES_UPDATE))
    end
  end

  describe "waf rule groups" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages/foobar/groups?direction=desc&match=all&mode=on&order=mode&page=1&per_page=50').
        to_return(response_body(SUCCESSFULL_WAF_RULE_GROUPS_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages/foo/groups/bar').
        to_return(response_body(SUCCESSFULL_WAF_RULE_GROUPS_DETAIL))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages/foo/groups/bar').
        to_return(response_body(SUCCESSFULL_WAF_RULE_GROUPS_UPDATE))
    end

    it "fails to list waf rule groups" do
      e = assert_raises(ArgumentError) { client.waf_rule_groups }
      e.message.must_equal('missing keywords: zone_id, package_id')
      e = assert_raises(RuntimeError) { client.waf_rule_groups(zone_id: nil, package_id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.waf_rule_groups(zone_id: valid_zone_id, package_id: nil) }
      e.message.must_equal('package_id required')
      e = assert_raises(RuntimeError) { client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'foo') }
      e.message.must_equal('mode must be one of on or off')
      e = assert_raises(RuntimeError) { client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'on', order: 'foo') }
      e.message.must_equal('order must be one of mode or rules_count')
      e = assert_raises(RuntimeError) { client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'on', order: 'mode', direction: 'foo') }
      e.message.must_equal('direction must be one of asc or desc')
      e = assert_raises(RuntimeError) { client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'on', order: 'mode', direction: 'asc', match: 'foo') }
      e.message.must_equal('match must be either all or any')
    end
    it "lists waf rule groups" do
      client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULE_GROUPS_LIST))
    end
    it "fails to get details for a single waf group" do
      e = assert_raises(ArgumentError) { client.waf_rule_group }
      e.message.must_equal('missing keywords: zone_id, package_id, id')
      e = assert_raises(RuntimeError) { client.waf_rule_group(zone_id: nil, package_id: 'foo', id: 'bar') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.waf_rule_group(zone_id: valid_zone_id, package_id: nil, id: 'bar') }
      e.message.must_equal('package_id required')
      e = assert_raises(RuntimeError) { client.waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: nil) }
      e.message.must_equal('id required')
    end
    it "gets details of a single waf group" do
      client.waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULE_GROUPS_DETAIL))
    end
    it "fails to update a waf group" do
      e = assert_raises(ArgumentError) { client.update_waf_rule_group }
      e.message.must_equal('missing keywords: zone_id, package_id, id')
      e = assert_raises(RuntimeError) { client.update_waf_rule_group(zone_id: nil, package_id: 'foo', id: 'bar') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_waf_rule_group(zone_id: valid_zone_id, package_id: nil, id: 'bar') }
      e.message.must_equal('package_id required')
      e = assert_raises(RuntimeError) { client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'blah') }
      e.message.must_equal('mode must be either on or off')
      client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'on')
      client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'off')
    end
    it "updates a waf group" do
      client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'off').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULE_GROUPS_UPDATE))
    end
  end

  describe "was rules" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/waf/packages/foo/rules?direction=desc&match=all&order=priority&page=1&per_page=50').
        to_return(response_body(SUCCESSFULL_WAF_RULES_LIST))
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages/foo/rules/bar').
        to_return(response_body(SUCCESSFULL_WAF_RULES_DETAIL))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/firewall/waf/packages/foo/rules/bar').
        to_return(response_body(SUCCESSFULL_WAF_RULES_UPDATE))
    end

    it "fails to list waf rules" do
      e = assert_raises(ArgumentError) { client.waf_rules }
      e.message.must_equal('missing keywords: zone_id, package_id')
      e = assert_raises(RuntimeError) { client.waf_rules(zone_id: nil, package_id: 'foo') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.waf_rules(zone_id: valid_zone_id, package_id: nil) }
      e.message.must_equal('package_id required')
      e = assert_raises(RuntimeError) { client.waf_rules(zone_id: valid_zone_id, package_id: 'foo', match: 'cat') }
      e.message.must_equal('match must be either all or any')
      e = assert_raises(RuntimeError) { client.waf_rules(zone_id: valid_zone_id, package_id: 'foo', order: 'bird') }
      e.message.must_equal('order must be one of priority, group_id, description')
      e = assert_raises(RuntimeError) { client.waf_rules(zone_id: valid_zone_id, package_id: 'foo', direction: 'bar') }
      e.message.must_equal('direction must be either asc or desc')
    end
    it "returns a list of waf rules" do
      client.waf_rules(zone_id: valid_zone_id, package_id: 'foo').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULES_LIST))
    end
    it "fails to get a waf rule" do
      e = assert_raises(ArgumentError) { client.waf_rule }
      e.message.must_equal('missing keywords: zone_id, package_id, id')
      e = assert_raises(RuntimeError) { client.waf_rule(zone_id: nil, package_id: 'foo', id: 'bar') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.waf_rule(zone_id: valid_zone_id, package_id: nil, id: 'bar') }
      e.message.must_equal('package_id required')
      e = assert_raises(RuntimeError) { client.waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: nil) }
      e.message.must_equal('id required')
    end
    it "gets details for a single waf rule" do
      client.waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: 'bar').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULES_DETAIL))
    end
    it "fails to update a waf rule" do
      e = assert_raises(ArgumentError) { client.update_waf_rule }
      e.message.must_equal('missing keywords: zone_id, package_id, id')
      e = assert_raises(RuntimeError) { client.update_waf_rule(zone_id: nil, package_id: 'foo', id: 'bar') }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_waf_rule(zone_id: valid_zone_id, package_id: nil, id: 'bar') }
      e.message.must_equal('package_id required')
      e = assert_raises(RuntimeError) { client.update_waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'boom') }
      e.message.must_equal('mode must be one of default, disable, simulate, block, challenge, on, off')
    end
    it "updates a waf rule" do
      client.update_waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'on').
        must_equal(JSON.parse(SUCCESSFULL_WAF_RULES_UPDATE))
    end
  end

  describe "analyze certificate" do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/ssl/analyze').
        to_return(response_body(SUCCESSFULL_CERT_ANALYZE))
    end

    it "fails to analyze a certificate" do
      e = assert_raises(ArgumentError) { client.analyze_certificate }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.analyze_certificate(zone_id: nil) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.analyze_certificate(zone_id: valid_zone_id, bundle_method: 'foo') }
      e.message.must_equal('valid bundle methods are ["ubiquitous", "optimal", "force"]')
    end
    it "analyzies a certificate" do
      client.analyze_certificate(zone_id: valid_zone_id, certificate: 'bar', bundle_method: 'ubiquitous').
        must_equal(JSON.parse(SUCCESSFULL_CERT_ANALYZE))
    end
  end

  describe "certificate packs" do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/ssl/certificate_packs').
        to_return(response_body(SUCCESSFULL_CERT_PACK_LIST))
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/ssl/certificate_packs').
        to_return(response_body(SUCCESSFULL_CERT_PACK_ORDER))
      stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/ssl/certificate_packs/foo').
        to_return(response_body(SUCCESSFULL_CERT_PACK_LIST))
    end

    it "fails to list certificate packs " do
      e = assert_raises(ArgumentError) { client.certificate_packs }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.certificate_packs(zone_id: nil) }
      e.message.must_equal('zone_id required')
    end
    it "lists certificate packs" do
      client.certificate_packs(zone_id: valid_zone_id).
        must_equal(JSON.parse(SUCCESSFULL_CERT_PACK_LIST))
    end
    it "fails to order certificate packs" do
      e = assert_raises(ArgumentError) { client.order_certificate_packs }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.order_certificate_packs(zone_id: valid_zone_id, hosts: 'foo') }
      e.message.must_equal('hosts must be an array of hostnames')
    end
    it "orders certificate packs" do
      client.order_certificate_packs(zone_id: valid_zone_id, hosts: ['foobar.com']).
        must_equal(JSON.parse(SUCCESSFULL_CERT_PACK_ORDER))
    end
    it "fails to update a certificate pack" do
      e = assert_raises(ArgumentError) { client.update_certificate_pack }
      e.message.must_equal('missing keywords: zone_id, id, hosts')
      e = assert_raises(RuntimeError) { client.update_certificate_pack(zone_id: nil, id: 'foo', hosts: ['bar']) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.update_certificate_pack(zone_id: valid_zone_id, id: nil, hosts: ['bar']) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_certificate_pack(zone_id: valid_zone_id, id: 'foo', hosts: []) }
      e.message.must_equal('hosts must be an array of hosts')
    end
    it "updates a certifiate pack" do
      client.update_certificate_pack(zone_id: valid_zone_id, id: 'foo', hosts: ['footothebar']).
        must_equal(JSON.parse(SUCCESSFULL_CERT_PACK_LIST))
    end
  end

  describe "zone verification" do
    before do
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/ssl/verification').
      to_return(response_body(SUCCESSFULL_VERIFY_SSL))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/ssl/verification?retry=true').
      to_return(response_body(SUCCESSFULL_VERIFY_SSL))
    end

    it "fails to verify a zone" do
      e = assert_raises(ArgumentError) { client.ssl_verification }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.ssl_verification(zone_id: nil)}
      e.message.must_equal('zone_id required')
    end
    it "verifies a zone" do
      client.ssl_verification(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_VERIFY_SSL))
      client.ssl_verification(zone_id: valid_zone_id, retry_verification: true).must_equal(JSON.parse(SUCCESSFULL_VERIFY_SSL))
    end
  end

  describe "zone subscriptions" do
    before do
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/subscription').
      to_return(response_body(SUCCESSFULL_ZONE_SUBSCRIPTION))
    stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/subscription').
      to_return(response_body(SUCCESSFULL_ZONE_SUBSCRIPTION_CREATE))
    end
    it "fails to list zone subscriptions" do
      e = assert_raises(ArgumentError) { client.zone_subscription }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.zone_subscription(zone_id: nil)}
      e.message.must_equal('zone_id required')
    end
    it "gets a zone subscription" do
      client.zone_subscription(zone_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_ZONE_SUBSCRIPTION))
    end
    it "fails to create a zone subscription" do
      e = assert_raises(ArgumentError) { client.create_zone_subscription }
      e.message.must_equal('missing keyword: zone_id')
      e = assert_raises(RuntimeError) { client.create_zone_subscription(zone_id: nil)}
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.create_zone_subscription(zone_id: valid_zone_id, state: 'foo')}
      e.message.must_equal('state must be one of ["Trial", "Provisioned", "Paid", "AwaitingPayment", "Cancelled", "Failed", "Expired"]')
      e = assert_raises(RuntimeError) { client.create_zone_subscription(zone_id: valid_zone_id, state: 'Failed', frequency: 'foo')}
      e.message.must_equal('frequency must be one of ["weekly", "monthly", "quarterly", "yearly"]')
    end
    it "creates a zone subscription" do
      client.create_zone_subscription(zone_id: valid_zone_id, state: 'Failed', frequency: 'weekly').
        must_equal(JSON.parse(SUCCESSFULL_ZONE_SUBSCRIPTION_CREATE))
    end
  end

  describe "organizations" do
    before do
    stub_request(:get, 'https://api.cloudflare.com/client/v4/organizations/abc1234').
      to_return(response_body(SUCCESSFULL_ORG_LIST))
    stub_request(:patch, 'https://api.cloudflare.com/client/v4/organizations/abc1234').
      to_return(response_body(SUCCESSFULL_ORG_UPDATE))
    end

    it "fails to get the details of an org" do
      e = assert_raises(ArgumentError) { client.organization }
      e.message.must_equal('missing keyword: org_id')
      e = assert_raises(RuntimeError) { client.organization(org_id: nil)}
      e.message.must_equal('org_id required')
    end
    it "get an org's details" do
      client.organization(org_id: valid_zone_id).must_equal(JSON.parse(SUCCESSFULL_ORG_LIST))
    end
    it "fails to update an org" do
      e = assert_raises(ArgumentError) { client.update_organization }
      e.message.must_equal('missing keyword: org_id')
      e = assert_raises(RuntimeError) { client.update_organization(org_id: nil) }
      e.message.must_equal('org_id required')
    end
    it "updates an org" do
      client.update_organization(org_id: valid_zone_id, name: 'foobar.com').
        must_equal(JSON.parse(SUCCESSFULL_ORG_UPDATE))
    end

  end

  describe "organization members" do
    before do
    stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/members").
      to_return(response_body(SUCCESSFULL_ORG_MEMBERS_LIST))
    stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/members/#{valid_user_id}").
      to_return(response_body(SUCCESSFULL_ORG_MEMBER_DETAIL))
    stub_request(:patch, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/members/#{valid_user_id}").
      to_return(response_body(SUCCESSFULL_ORG_MEMBER_UPDATE))
    stub_request(:delete, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/members/#{valid_user_id}").
      to_return(response_body(SUCCESSFULL_ORG_MEMBER_DELETE))
    end

    it "fails to get org members" do
      e = assert_raises(ArgumentError) { client.organization_members }
      e.message.must_equal('missing keyword: org_id')
      e = assert_raises(RuntimeError) { client.organization_members(org_id: nil) }
      e.message.must_equal('org_id required')
    end
    it "returns a list of org members" do
      client.organization_members(org_id: valid_org_id).must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBERS_LIST))
    end
    it "fails to get details for an org member" do
      e = assert_raises(ArgumentError) { client.organization_member }
      e.message.must_equal('missing keywords: org_id, id')
      e = assert_raises(RuntimeError) { client.organization_member(org_id: nil, id: 'bob') }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.organization_member(org_id: valid_org_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "gets the details for an org member" do
      client.organization_member(org_id: valid_org_id, id: valid_user_id).must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBER_DETAIL))
    end
    it "fails to updates org member roles" do
      e = assert_raises(ArgumentError) { client.update_organization_member_roles }
      e.message.must_equal('missing keywords: org_id, id, roles')
      e = assert_raises(RuntimeError) { client.update_organization_member_roles(org_id: nil, id: 'bob', roles: nil) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.update_organization_member_roles(org_id: valid_org_id, id: nil, roles: nil) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.update_organization_member_roles(org_id: valid_org_id, id: valid_user_id, roles: nil ) }
      e.message.must_equal('roles must be an array of roles')
      e = assert_raises(RuntimeError) { client.update_organization_member_roles(org_id: valid_org_id, id: valid_user_id, roles: [] ) }
      e.message.must_equal('roles cannot be empty')
    end
    it "updates an org members roles" do
      client.update_organization_member_roles(org_id: valid_org_id, id: valid_user_id, roles: ['foo', 'bar']).
        must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBER_UPDATE))
    end
    it "fails to remove an org member" do
      e = assert_raises(ArgumentError) { client.remove_org_member }
      e.message.must_equal('missing keywords: org_id, id')
      e = assert_raises(RuntimeError) { client.remove_org_member(org_id: nil, id: valid_user_id) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.remove_org_member(org_id: valid_org_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "removes and org member" do
      client.remove_org_member(org_id: valid_org_id, id: valid_user_id).
        must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBER_DELETE))
    end
  end

  describe "organization invitations" do
    before do
    stub_request(:post, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/invites").
      to_return(response_body(SUCCESSFULL_ORG_MEMBERS_INVITE_CREATE))
    stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/invites").
      to_return(response_body(SUCCESSFULL_ORG_MEMBERS_INVITES_LIST))
    stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/invites/1234").
      to_return(response_body(SUCCESSFULL_ORG_MEMBERS_INVITE_DETAIL))
    stub_request(:patch, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/invites/1234").
      to_return(response_body(SUCCESSFULL_ORG_MEMBERS_INVITE_DETAIL))
    stub_request(:delete, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/invites/1234").
      to_return(response_body(SUCCESSFULL_ORG_MEMBERS_INVITE_DELETE))

    end

    it "fails to create an organization invite" do
      e = assert_raises(ArgumentError) { client.create_organization_invite }
      e.message.must_equal('missing keywords: org_id, email, roles')
      e = assert_raises(RuntimeError) { client.create_organization_invite(org_id: nil, email: valid_user_email, roles: ['foo'], auto_accept: true) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.create_organization_invite(org_id: valid_org_id, email: nil, roles: ['foo'], auto_accept: true) }
      e.message.must_equal('email required')
      e = assert_raises(RuntimeError) { client.create_organization_invite(org_id: valid_org_id, email: valid_user_email, roles: 'foo', auto_accept: true) }
      e.message.must_equal('roles must be an array of roles')
      e = assert_raises(RuntimeError) { client.create_organization_invite(org_id: valid_org_id, email: valid_user_email, roles: [], auto_accept: true) }
      e.message.must_equal('roles cannot be empty')
      e = assert_raises(RuntimeError) { client.create_organization_invite(org_id: valid_org_id, email: valid_user_email, roles: ['foo', 'bar'], auto_accept: 'foo') }
      e.message.must_equal('auto_accept must be a boolean value')
    end
    it "creates an organization invite" do
      client.create_organization_invite(org_id: valid_org_id, email: valid_user_email, roles: ['foo', 'bar'], auto_accept: false).
        must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_CREATE))
    end
    it "fails to list invites for an organization" do
      e = assert_raises(ArgumentError) { client.organization_invites }
      e.message.must_equal('missing keyword: org_id')
      e = assert_raises(RuntimeError) { client.organization_invites(org_id: nil) }
      e.message.must_equal('org_id required')
    end
    it "lists invutes for an organization" do
      client.organization_invites(org_id: valid_org_id).must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITES_LIST))
    end
    it "fails to list details of an organization invite" do
      e = assert_raises(ArgumentError) { client.organization_invite }
      e.message.must_equal('missing keywords: org_id, id')
      e = assert_raises(RuntimeError) { client.organization_invite(org_id: nil, id: 1234) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.organization_invite(org_id: valid_org_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "gets details of an organization invite" do
      client.organization_invite(org_id: valid_org_id, id: 1234).
        must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_DETAIL))
    end
    it "fails to update the roles for an organization invite" do
      e = assert_raises(ArgumentError) { client.updates_organization_invite_roles }
      e.message.must_equal('missing keywords: org_id, id, roles')
      e = assert_raises(RuntimeError) { client.updates_organization_invite_roles(org_id: nil, id: 1234, roles: ['foo']) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.updates_organization_invite_roles(org_id: valid_org_id, id: nil, roles: ['foo']) }
      e.message.must_equal('id required')
      e = assert_raises(RuntimeError) { client.updates_organization_invite_roles(org_id: valid_org_id, id: 1234, roles: nil) }
      e.message.must_equal('roles must be an array of roles')
      e = assert_raises(RuntimeError) { client.updates_organization_invite_roles(org_id: valid_org_id, id: 1234, roles: []) }
      e.message.must_equal('roles cannot be empty')
    end
    it "updates the roles for an organization invite" do
      client.updates_organization_invite_roles(org_id: valid_org_id, id: 1234, roles: ['foo', 'bar']).
        must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_DETAIL))
    end
    it "fails to delete an org invite" do
      e = assert_raises(ArgumentError) { client.cancel_organization_invite }
      e.message.must_equal('missing keywords: org_id, id')
      e = assert_raises(RuntimeError) { client.cancel_organization_invite(org_id: nil, id: nil) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.cancel_organization_invite(org_id: valid_org_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "deletes an organization invites" do
      client.cancel_organization_invite(org_id: valid_org_id, id: 1234).
        must_equal(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_DELETE))
    end
  end

  describe "organization roles" do
    before do
    stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/roles").
      to_return(response_body(SUCCESSFUL_ORG_ROLES))
    stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/roles/1234").
      to_return(response_body(SUCCESSFUL_ORG_ROLE_DETAIL))
    end

    it "fails to list organization roles" do
      e = assert_raises(ArgumentError) { client.organization_roles }
      e.message.must_equal("missing keyword: org_id")
      e = assert_raises(RuntimeError) { client.organization_roles(org_id: nil) }
      e.message.must_equal('org_id required')
    end
    it "lists organization roles" do
      client.organization_roles(org_id: valid_org_id).must_equal(JSON.parse(SUCCESSFUL_ORG_ROLES))
    end
    it "fails to get details of an organization role" do
      e = assert_raises(ArgumentError) { client.organization_role }
      e.message.must_equal("missing keywords: org_id, id")
      e = assert_raises(RuntimeError) { client.organization_role(org_id: nil, id: nil) }
      e.message.must_equal("org_id required")
      e = assert_raises(RuntimeError) { client.organization_role(org_id: valid_org_id, id: nil) }
      e.message.must_equal("id required")
    end
    it "gets details of an organization role" do
      client.organization_role(org_id: valid_org_id, id: 1234).
        must_equal(JSON.parse(SUCCESSFUL_ORG_ROLE_DETAIL))
    end
  end

  describe "organzation level firewall rules" do
    before do
    stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/firewall/access_rules/rules?configuration_target=ip&configuration_value=IP&direction=asc&match=all&mode=block&order=mode&page=1&per_page=50").
      to_return(response_body(SUCCESSFUL_ORG_FIREWALL_RULES_LIST))
    stub_request(:post, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/firewall/access_rules/rules").
      to_return(response_body(SUCCESSFUL_ORG_FIREWALL_RULES_CREATE))
    stub_request(:delete, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/firewall/access_rules/rules/1234").
      to_return(response_body(SUCCESSFUL_ORG_FIREWALL_RULES_DELETE))
    end

    it "fails to list organization level firwall rules" do
      e = assert_raises(ArgumentError) { client.org_level_firewall_rules }
      e.message.must_equal('missing keyword: org_id')
      e = assert_raises(RuntimeError) { client.org_level_firewall_rules(org_id: nil) }
      e.message.must_equal("org_id required")
    end
    it "lists organization level firewall rules" do
      client.org_level_firewall_rules(org_id: valid_org_id, mode: 'block', match: 'all', configuration_value: 'IP', order: "mode", configuration_target: 'ip', direction: 'asc').
        must_equal(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_LIST))
    end
    it "fails to create an org level access rule" do
      e = assert_raises(ArgumentError) { client.create_org_access_rule }
      e.message.must_equal('missing keyword: org_id')
      e = assert_raises(RuntimeError) { client.create_org_access_rule(org_id: nil, mode: nil, configuration: nil) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.create_org_access_rule(org_id: valid_org_id, mode: 'bob', configuration: nil) }
      e.message.must_equal('mode must be one of block, challenge, whitelist')
      e = assert_raises(RuntimeError) { client.create_org_access_rule(org_id: valid_org_id, mode: 'block', configuration: 'foo') }
      e.message.must_equal('configuration must be a hash')
      e = assert_raises(RuntimeError) { client.create_org_access_rule(org_id: valid_org_id, mode: 'block', configuration: {}) }
      e.message.must_equal('configuration cannot be empty')
    end
    it "creates an org level access rules" do
      client.create_org_access_rule(org_id: valid_org_id, mode: 'block', configuration: {foo: 'bar'}).
        must_equal(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_CREATE))
    end
    it "fails to delete an org level access rule" do
      e = assert_raises(ArgumentError) { client.delete_org_access_rule }
      e.message.must_equal('missing keywords: org_id, id')
      e = assert_raises(RuntimeError) { client.delete_org_access_rule(org_id: nil, id: nil) }
      e.message.must_equal('org_id required')
      e = assert_raises(RuntimeError) { client.delete_org_access_rule(org_id: valid_org_id, id: nil) }
      e.message.must_equal('id required')
    end
    it "deletes an org level access rule" do
      client.delete_org_access_rule(org_id: valid_org_id, id: 1234).
        must_equal(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_DELETE))
    end
  end




  describe "logs api" do
    let(:valid_start_time) { 1495825365 }
    let(:valid_end_time) { 1495825610 }
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

    it "fails to get logs via timestamps" do
      e = assert_raises(ArgumentError) { client.get_logs_by_time }
      e.message.must_equal('missing keywords: zone_id, start_time')
      e = assert_raises(RuntimeError) { client.get_logs_by_time(zone_id: nil, start_time: valid_start_time) }
      e.message.must_equal('zone_id required')
      e = assert_raises(RuntimeError) { client.get_logs_by_time(zone_id: valid_zone_id, start_time: nil) }
      e.message.must_equal('start_time required')
    end
    it "fails with invalid timestamps" do
      e = assert_raises(RuntimeError) { client.get_logs_by_time(zone_id: valid_zone_id, start_time: 'bob') }
      e.message.must_equal('start_time must be a valid unix timestamp')
      e = assert_raises(RuntimeError) { client.get_logs_by_time(zone_id: valid_zone_id, start_time: valid_start_time, end_time: 'cat') }
      e.message.must_equal('end_time must be a valid unix timestamp')
    end
    it "get's logs via timestamps" do
      # note, these are raw not json encoded
      client.get_logs_by_time(zone_id: valid_zone_id, start_time: valid_start_time).
        must_equal(SUCCESSFULL_LOG_MESSAGE)
      client.get_logs_by_time(zone_id: valid_zone_id, start_time: valid_start_time, end_time: valid_end_time).
        must_equal(SUCCESSFULL_LOG_MESSAGE)
    end
    it "fails to get a log by rayid" do
      e = assert_raises(ArgumentError) { client.get_log }
      e.message.must_equal('missing keywords: zone_id, ray_id')
    end
    it "get's a log via rayid" do
      client.get_log(zone_id: valid_zone_id, ray_id: 'somerayid').must_equal(SUCCESSFULL_LOG_MESSAGE)
    end
    it "fails to get logs since a given ray_id" do
      e = assert_raises(ArgumentError) { client.get_logs_since }
      e.message.must_equal('missing keywords: zone_id, ray_id')
      e = assert_raises(RuntimeError) { client.get_logs_since(zone_id: valid_zone_id, ray_id: 'foo', end_time: 'bob') }
      e.message.must_equal('end time must be a valid unix timestamp')
    end
    it "gets logs since a given ray_id" do
      client.get_logs_since(zone_id: valid_zone_id, ray_id: 'foo', end_time: valid_end_time, count: 5).
        must_equal(SUCCESSFULL_LOG_MESSAGE)
    end
  end
end
