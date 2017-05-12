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
    assert_raises(RuntimeError) { CloudflareClient.new() }
  end
  it "raises when missing auth_email" do
    assert_raises(RuntimeError) { CloudflareClient.new(auth_key: "somefakekey") }
  end

  describe "zone operations" do
    let(:successful_zone_body) {'{"result": {"id": "3498951717b450da33b72a1fc1b47558"}, "success": true, "errors": [], "messages": []}'}
    let(:fail_zone) {'{"success":false,"errors":[{"code":7003,"message":"Could not route to \/zones\/blahblahblah, perhaps your object identifier is invalid?"},{"code":7000,"message":"No route for that URI"}],"messages":[],"result":null}'}
    let(:failure_body) {'{"result": {"id": "3498951717b450da33b72a1fc1b47558"}, "success": true, "errors": [], "messages": []}'}
    let(:client) {CloudflareClient.new(auth_key: "somefakekey", email: "foo@bar.com")}

    around do |test|
      test.call
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
        to_return(response_body(fail_zone).merge({status: 400}))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/abc1234").
        to_return(response_body(successful_zone_body))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/abc1234").
        to_return(response_body(successful_zone_body))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/abc1234/purge_cache").
        to_return(response_body(successful_zone_body))
    end
    it "creates a zone" do
      client.create_zone(name: 'testzone.com', organization: {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'})
    end
    it "fails to create a zone when missing a name" do
      assert_raises(RuntimeError) {client.create_zone(organization: {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'})}
    end
    it "fails to create a zone when missing org data" do
      assert_raises(RuntimeError) {client.create_zone(name: 'foobar.com')}
    end
    it "fails to delete a zone" do
      assert_raises(RuntimeError) {client.delete_zone()}
    end
    it "deletes a zone" do
      client.delete_zone(zone_id:"abc1234")
    end
    it "requests zone activcation check succeedes" do
      client.zone_activation_check(zone_id: '1234abcd')
    end
    it "requests zone activcation check fails" do
      assert_raises(RuntimeError) { client.zone_activation_check() }
    end
    it "lists all zones" do
      client.list_zones()
    end
    it "searches for a single zone" do
      client.list_zones(name: "testzonename.com")
    end
    it "returns details for a single zone" do
      client.zone_details(zone_id: "1234abc")
    end
    it "fails when getting details for a non-existent zone" do
      assert_raises(RuntimeError) {client.zone_details(zone_id: "shouldfail")}
    end
    it "fails to edit an existing zone" do
      assert_raises(RuntimeError) {client.edit_zone()}
    end
    it "edits and existing zone" do
      client.edit_zone(zone_id: 'abc1234', vanity_name_servers: ['ns1.foo.com', 'ns2.foo.com'])
    end
    it "fails to purge the cache on a zone" do
      assert_raises(RuntimeError) { client.purge_zone_cache(zone_id: 'abc1234') }
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
  end
end
