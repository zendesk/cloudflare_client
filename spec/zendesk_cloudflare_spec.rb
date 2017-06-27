# rubocop:disable LineLength

require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered! uncovered: 2

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
      expect { client.org_level_firewall_rules }.to raise_error(ArgumentError, 'missing keyword: org_id')
      expect { client.org_level_firewall_rules(org_id: nil) }.to raise_error(RuntimeError, "org_id required")
    end

    it "lists organization level firewall rules" do
      result = client.org_level_firewall_rules(
        org_id:               valid_org_id,
        mode:                 'block',
        match:                'all',
        configuration_value:  'IP',
        order:                "mode",
        configuration_target: 'ip',
        direction:            'asc'
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_LIST, symbolize_names: true))
    end

    it "fails to create an org level access rule" do
      expect { client.create_org_access_rule }.to raise_error(ArgumentError, 'missing keyword: org_id')

      expect do
        client.create_org_access_rule(org_id: nil, mode: nil, configuration: nil)
      end.to raise_error(RuntimeError, 'org_id required')

      expect do
        client.create_org_access_rule(org_id: valid_org_id, mode: 'bob', configuration: nil)
      end.to raise_error(RuntimeError, 'mode must be one of block, challenge, whitelist')

      expect do
        client.create_org_access_rule(org_id: valid_org_id, mode: 'block', configuration: 'foo')
      end.to raise_error(RuntimeError, 'configuration must be a hash')

      expect do
        client.create_org_access_rule(org_id: valid_org_id, mode: 'block', configuration: {})
      end.to raise_error(RuntimeError, 'configuration cannot be empty')
    end

    it "creates an org level access rules" do
      result = client.create_org_access_rule(org_id: valid_org_id, mode: 'block', configuration: {foo: 'bar'})
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_CREATE, symbolize_names: true))
    end

    it "fails to delete an org level access rule" do
      expect { client.delete_org_access_rule }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.delete_org_access_rule(org_id: nil, id: nil) }.to raise_error(RuntimeError, 'org_id required')
      expect { client.delete_org_access_rule(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "deletes an org level access rule" do
      result = client.delete_org_access_rule(org_id: valid_org_id, id: 1234)
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_DELETE, symbolize_names: true))
    end
  end

  describe "organization railguns" do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/railguns").
        to_return(response_body(SUCCESSFUL_ORG_RAILGUN_CREATE))
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/railguns?page=1&per_page=50&direction=desc").
        to_return(response_body(SUCCESSFUL_ORG_RAILGUN_LIST))
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/railguns/foobar").
        to_return(response_body(SUCCESSFUL_ORG_RAILGUN_DETAILS))
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/railguns/foobar/zones").
        to_return(response_body(SUCCESSFUL_ORG_RAILGUN_ZONES))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/railguns/foobar").
        to_return(response_body(SUCCESSFUL_ORG_RAILGUN_ENABLE))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/railguns/foobar").
        to_return(response_body(SUCCESSFUL_ORG_RAILGUN_DELETE))
    end

    it "fails to create an org railgun" do
      expect { client.create_org_railguns }.to raise_error(ArgumentError, 'missing keywords: org_id, name')
      expect { client.create_org_railguns(org_id: nil, name: 'foo') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.create_org_railguns(org_id: valid_org_id, name: nil) }.to raise_error(RuntimeError, 'name required')
    end

    it "creates an org railgun" do
      result = client.create_org_railguns(org_id: valid_org_id, name: "some_name")
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_CREATE, symbolize_names: true))
    end

    it "fails to list an orgs railguns" do
      expect { client.org_railguns }.to raise_error(ArgumentError, 'missing keyword: org_id')

      expect { client.org_railguns(org_id: nil) }.to raise_error(RuntimeError, 'org_id required')

      expect do
        client.org_railguns(org_id: valid_org_id, direction: 'foobar')
      end.to raise_error(RuntimeError, 'direction must be either asc or desc')
    end

    it "lists an orgs railguns" do
      result = client.org_railguns(org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_LIST, symbolize_names: true))
    end

    it "fails to get details for a railgun" do
      expect { client.org_railgun }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.org_railgun(org_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.org_railgun(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets details for an org railgun" do
      result = client.org_railgun(org_id: valid_org_id, id: 'foobar')
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_DETAILS, symbolize_names: true))
    end

    it "fails to get zones connected to an org railgun" do
      expect { client.org_railgun_connected_zones }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.org_railgun_connected_zones(org_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.org_railgun_connected_zones(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets zones connected to an org railgun" do
      result = client.org_railgun_connected_zones(org_id: valid_org_id, id: 'foobar')
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_ZONES, symbolize_names: true))
    end

    it "fails to enable or disable a railgun" do
      expect { client.enable_org_railgun }.to raise_error(ArgumentError, 'missing keywords: org_id, id, enabled')

      expect do
        client.enable_org_railgun(org_id: nil, id: 'foobar', enabled: true)
      end.to raise_error(RuntimeError, 'org_id required')

      expect do
        client.enable_org_railgun(org_id: valid_org_id, id: nil, enabled: true)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.enable_org_railgun(org_id: valid_org_id, id: 'foobar', enabled: nil)
      end.to raise_error(RuntimeError, 'enabled required')

      expect do
        client.enable_org_railgun(org_id: valid_org_id, id: 'foobar', enabled: 'bob')
      end.to raise_error(RuntimeError, 'enabled must be true or false')
    end

    it "enables or disables a railgun" do
      result = client.enable_org_railgun(org_id: valid_org_id, id: 'foobar', enabled: true)
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_ENABLE, symbolize_names: true))
    end

    it "fails to delete an org railgun" do
      expect { client.delete_org_railgun }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.delete_org_railgun(org_id: nil, id: 'foobar') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.delete_org_railgun(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "deltes an org railgun" do
      result = client.delete_org_railgun(org_id: valid_org_id, id: 'foobar')
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_DELETE, symbolize_names: true))
    end
  end

  describe "cloudflare CA" do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/certificates").
        to_return(response_body(SUCCESSFUL_CERTS))
      stub_request(:post, "https://api.cloudflare.com/client/v4/certificates").
        to_return(response_body(SUCCESSFUL_CERTS_CREATE))
      stub_request(:get, "https://api.cloudflare.com/client/v4/certificates/somecertid").
        to_return(response_body(SUCCESSFUL_CERTS_DETAILS))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/certificates/somecertid").
        to_return(response_body(SUCCESSFUL_CERTS_REVOKE))
    end

    it "lists cloudflare certs" do
      expect(client.certificates).to eq(JSON.parse(SUCCESSFUL_CERTS, symbolize_names: true))
    end

    it "fails to create a certificate" do
      expect { client.create_certificate }.to raise_error(ArgumentError, 'missing keyword: hostnames')

      expect { client.create_certificate(hostnames: 'foo') }.to raise_error(RuntimeError, 'hostnames must be an array')

      expect { client.create_certificate(hostnames: []) }.to raise_error(RuntimeError, 'hostnames cannot be empty')

      expect do
        client.create_certificate(hostnames: ['foobar.com'], requested_validity: 1)
      end.to raise_error(RuntimeError, 'requested_validity must be one of [7, 30, 90, 365, 730, 1095, 5475]')

      expect do
        client.create_certificate(hostnames: ['foobar.com'], requested_validity: 7, request_type: 'bob')
      end.to raise_error(RuntimeError, 'request type must be one of ["origin-rsa", "origin-ecc", "keyless-certificate"]')
    end

    it "creates a certificate" do
      result = client.create_certificate(
        hostnames:          ['foobar.com'],
        requested_validity: 7,
        request_type:       'origin-rsa',
        csr:                'foo'
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_CERTS_CREATE, symbolize_names: true))
    end

    it "fails to get details of a certficiate" do
      expect { client.certificate }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.certificate(id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets details for a certificate" do
      result = client.certificate(id: 'somecertid')
      expect(result).to eq(JSON.parse(SUCCESSFUL_CERTS_DETAILS, symbolize_names: true))
    end

    it "fails to revoke a certificate" do
      expect { client.revoke_certificate }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.revoke_certificate(id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "revokes a certificate" do
      result = client.revoke_certificate(id: 'somecertid')
      expect(result).to eq(JSON.parse(SUCCESSFUL_CERTS_REVOKE, symbolize_names: true))
    end
  end

  describe "virtual DNS" do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/user/virtual_dns").
        to_return(response_body(SUCCESSFUL_CLUSTER_LIST))
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/virtual_dns").
        to_return(response_body(SUCCESSFUL_CLUSTER_LIST))
      stub_request(:post, "https://api.cloudflare.com/client/v4/user/virtual_dns").
        to_return(response_body(SUCCESSFUL_CLUSTER_CREATE))
      stub_request(:post, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/virtual_dns").
        to_return(response_body(SUCCESSFUL_CLUSTER_CREATE))
      stub_request(:get, "https://api.cloudflare.com/client/v4/user/virtual_dns/foobar").
        to_return(response_body(SUCCESSFUL_CLUSTER_DETAILS))
      stub_request(:get, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/virtual_dns/foobar").
        to_return(response_body(SUCCESSFUL_CLUSTER_DETAILS))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/user/virtual_dns/foobar").
        to_return(response_body(SUCCESSFUL_CLUSTER_DELETE))
      stub_request(:delete, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/virtual_dns/foobar").
        to_return(response_body(SUCCESSFUL_CLUSTER_DELETE))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/user/virtual_dns/foobar").
        to_return(response_body(SUCCESSFUL_CLUSTER_DETAILS))
      stub_request(:patch, "https://api.cloudflare.com/client/v4/organizations/#{valid_org_id}/virtual_dns/foobar").
        to_return(response_body(SUCCESSFUL_CLUSTER_DETAILS))
    end

    it "fails to list virutal dns clusters" do
      expect { client.virtual_dns_clusters }.to raise_error(ArgumentError, 'missing keyword: scope')

      expect do
        client.virtual_dns_clusters(scope: 'bob')
      end.to raise_error(RuntimeError, 'scope must be user or organization')

      expect { client.virtual_dns_clusters(scope: 'organization') }.to raise_error(RuntimeError, 'org_id required')
    end

    it "lists virtual dns clusters for a user" do
      result = client.virtual_dns_clusters(scope: 'user')
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_LIST, symbolize_names: true))
    end

    it "lists virtual dns clusters for a org" do
      result = client.virtual_dns_clusters(scope: 'organization', org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_LIST, symbolize_names: true))
    end

    it "fails to create a dns cluster" do
      expect do
        client.create_virtual_dns_cluster
      end.to raise_error(ArgumentError, 'missing keywords: name, origin_ips, scope')

      expect do
        client.create_virtual_dns_cluster(name: nil, origin_ips: 'foo', scope: 'cat')
      end.to raise_error(RuntimeError, 'name required')

      expect do
        client.create_virtual_dns_cluster(name: 'foo', origin_ips: 'bar', scope: 'cat')
      end.to raise_error(RuntimeError, 'origin_ips must be an array of ips (v4 or v6)')

      expect do
        client.create_virtual_dns_cluster(name: 'foo', origin_ips: ['bar'], scope: 'cat', deprecate_any_request: 'bob')
      end.to raise_error(RuntimeError, 'deprecate_any_request must be boolean')

      expect do
        client.create_virtual_dns_cluster(name: 'foo', origin_ips: ['bar'], scope: 'cat', deprecate_any_request: true)
      end.to raise_error(RuntimeError, 'scope must be user or organization')

      expect do
        client.create_virtual_dns_cluster(
          name:                  'foo',
          origin_ips:            ['bar'],
          scope:                 'organization',
          deprecate_any_request: true
        )
      end.to raise_error(RuntimeError, 'org_id required')
    end

    it "creates a user dns cluster" do
      result = client.create_virtual_dns_cluster(
        name:                  'foo',
        origin_ips:            ['bar'],
        deprecate_any_request: true,
        scope:                 'user'
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_CREATE, symbolize_names: true))
    end

    it "creates an organization dns cluster" do
      result = client.create_virtual_dns_cluster(
        name:                  'foo',
        origin_ips:            ['bar'],
        deprecate_any_request: true,
        scope:                 'organization',
        org_id:                valid_org_id
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_CREATE, symbolize_names: true))
    end

    it "fails to get deatails of a cluster" do
      expect { client.virtual_dns_cluster }.to raise_error(ArgumentError, 'missing keywords: id, scope')

      expect { client.virtual_dns_cluster(id: nil, scope: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.virtual_dns_cluster(id: 'foo', scope: 'bar')
      end.to raise_error(RuntimeError, 'scope must be user or organization')

      expect do
        client.virtual_dns_cluster(id: 'foo', scope: 'organization', org_id: nil)
      end.to raise_error(RuntimeError, 'org_id required')
    end

    it "gets details of a user cluster" do
      result = client.virtual_dns_cluster(id: 'foobar', scope: 'user')
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS, symbolize_names: true))
    end

    it "gets details of an organization cluster" do
      result = client.virtual_dns_cluster(id: 'foobar', scope: 'organization', org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS, symbolize_names: true))
    end

    it "fails to delete a virtual dns cluster" do
      expect { client.delete_virtual_dns_cluster }.to raise_error(ArgumentError, 'missing keywords: id, scope')

      expect { client.delete_virtual_dns_cluster(id: nil, scope: 'foo') }.to raise_error(RuntimeError, 'id required')

      expect do
        client.delete_virtual_dns_cluster(id: 'foo', scope: 'foo')
      end.to raise_error(RuntimeError, 'scope must be user or organization')

      expect do
        client.delete_virtual_dns_cluster(id: 'foo', scope: 'organization')
      end.to raise_error(RuntimeError, 'org_id required')
    end

    it "deletes a dns user cluster" do
      result = client.delete_virtual_dns_cluster(id: 'foobar', scope: 'user')
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DELETE, symbolize_names: true))
    end

    it "deletes a dns an organization's cluster" do
      result = client.delete_virtual_dns_cluster(id: 'foobar', scope: 'organization', org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DELETE, symbolize_names: true))
    end

    it "fails to update a dns cluster" do
      expect { client.update_virtual_dns_cluster }.to raise_error(ArgumentError, 'missing keywords: id, scope')

      expect { client.update_virtual_dns_cluster(id: nil, scope: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_virtual_dns_cluster(id: 'foo', origin_ips: 'bar', scope: nil)
      end.to raise_error(RuntimeError, 'origin_ips must be an array of ips (v4 or v6)')

      expect do
        client.update_virtual_dns_cluster(id: 'foo', scope: nil, origin_ips: ['bar'], deprecate_any_request: 'bob')
      end.to raise_error(RuntimeError, 'deprecate_any_request must be boolean')

      expect do
        client.update_virtual_dns_cluster(id: 'foo', origin_ips: ['bar'], scope: 'bob')
      end.to raise_error(RuntimeError, 'scope must be user or organization')
    end

    it "updates a user dns cluster" do
      result = client.update_virtual_dns_cluster(
        id:                    'foobar',
        scope:                 'user',
        origin_ips:            ['10.1.1.1'],
        minimum_cache_ttl:     500,
        maximum_cache_ttl:     900,
        deprecate_any_request: false,
        ratelimit:             0
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS, symbolize_names: true))
    end

    it "updates an organization dns cluster" do
      result = client.update_virtual_dns_cluster(
        id:                    'foobar',
        scope:                 'organization',
        org_id:                valid_org_id,
        origin_ips:            ['10.1.1.1'],
        minimum_cache_ttl:     500,
        maximum_cache_ttl:     900,
        deprecate_any_request: false,
        ratelimit:             0
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS, symbolize_names: true))
    end
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
