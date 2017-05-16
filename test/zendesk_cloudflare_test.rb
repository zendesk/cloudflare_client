# rubocop:disable LineLength
require_relative "test_helper"
SingleCov.covered!

require 'zendesk_cloudflare'

describe CloudflareClient do
  def response_body(body)
    {body: body, headers: {'Content-Type': 'application/json'}}
  end

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

  describe "zone operations" do
    let(:successful_zone_body) { '{"result": {"id": "3498951717b450da33b72a1fc1b47558"}, "success": true, "errors": [], "messages": []}' }
    let(:fail_zone) { '{"success":false,"errors":[{"code":7003,"message":"Could not route to \/zones\/blahblahblah, perhaps your object identifier is invalid?"},{"code":7000,"message":"No route for that URI"}],"messages":[],"result":null}' }
    let(:failure_body) { '{"result": {"id": "3498951717b450da33b72a1fc1b47558"}, "success": true, "errors": [], "messages": []}' }
    let(:client) { CloudflareClient.new(auth_key: "somefakekey", email: "foo@bar.com") }

    around do |test|
      test&.call
    end

    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones").
        to_return(response_body(successful_zone_body))
      stub_request(:put, "https://api.cloudflare.com/client/v4/zones/1234abcd/activation_check").
        to_return(response_body(successful_zone_body))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones?page=1&per_page=50").
        to_return(response_body(successful_zone_body))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones?name=testzonename.com&page=1&per_page=50").
        to_return(response_body(successful_zone_body))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/1234abc").
        to_return(response_body(successful_zone_body))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/shouldfail").
        to_return(response_body(fail_zone).merge(status: 400))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/abc1234").
        to_return(response_body(successful_zone_body))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/abc1234").
        to_return(response_body(successful_zone_body))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/abc1234/purge_cache").
        to_return(response_body(successful_zone_body))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/settings").
        to_return(response_body(successful_zone_body))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/").
        to_return(response_body(successful_zone_body))
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/abc1234/settings/always_online").
        to_return(response_body(successful_zone_body))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/abc1234/settings").
        to_return(response_body(successful_zone_body))
    end
    it "creates a zone" do
      client.create_zone(name: 'testzone.com', organization: {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'})
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
      client.delete_zone(zone_id: "abc1234")
    end
    it "requests zone activcation check succeedes" do
      client.zone_activation_check(zone_id: '1234abcd')
    end
    it "requests zone activcation check fails" do
      e = assert_raises(RuntimeError) { client.zone_activation_check }
      e.message.must_equal("zone_id required")
    end
    it "lists all zones" do
      client.list_zones
    end
    it "searches for a single zone" do
      client.list_zones(name: "testzonename.com")
    end
    it "returns details for a single zone" do
      client.zone_details(zone_id: "1234abc")
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
      client.edit_zone(zone_id: 'abc1234', vanity_name_servers: ['ns1.foo.com', 'ns2.foo.com'])
    end
    it "fails to purge the cache on a zone" do
      e = assert_raises(RuntimeError) { client.purge_zone_cache(zone_id: 'abc1234') }
      e.message.must_include("specify a combination tags[], files[] or purge_everything")
    end
    it "succeedes in purging the entire cache on a zone" do
      client.purge_zone_cache(zone_id: 'abc1234', purge_everything: true)
    end
    it "succeedes in purging a file from cache on a zone" do
      client.purge_zone_cache(zone_id: 'abc1234', files: ['/some_random_file'])
    end
    it "succeedes in purging a tag from cache on a zone" do
      client.purge_zone_cache(zone_id: 'abc1234', tags: ['tag-to-purge'])
    end
    it "fails to get all settings for a zone " do
      e = assert_raises(RuntimeError) { client.zone_settings }
      e.message.must_equal("zone_id required")
    end
    it "gets all settings for a zone" do
      client.zone_settings(zone_id: 'abc1234')
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
end
