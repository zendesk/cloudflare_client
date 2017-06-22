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
      expect do
        client.create_keyless_ssl_config
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, host, port, certificate')

      expect do
        client.create_keyless_ssl_config(zone_id: nil, host: 'foo', port: 1234, certificate: 'bar')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.create_keyless_ssl_config(zone_id: valid_zone_id, host: nil, port: 1234, certificate: 'bar')
      end.to raise_error(RuntimeError, 'host required')

      expect do
        client.create_keyless_ssl_config(zone_id: valid_zone_id, host: 'foo', port: 1234, certificate: nil)
      end.to raise_error(RuntimeError, 'certificate required')

      expect do
        client.create_keyless_ssl_config(zone_id: valid_zone_id, host: 'foobar', port: 1234, certificate: 'cert data', bundle_method: 'foo')
      end.to raise_error(RuntimeError, 'valid bundle methods are ["ubiquitous", "optimal", "force"]')
    end

    it "creates a keyless ssl config" do
      result = client.create_keyless_ssl_config(zone_id: valid_zone_id, host: 'foobar', certificate: 'cert data', port: 1245)
      expect(result).to eq(JSON.parse(SUCCESSFULL_KEYLESS_SSL_CREATE))
    end

    it "fails to list keyless_ssl_configs" do
      expect { client.keyless_ssl_configs }.to raise_error(ArgumentError, 'missing keyword: zone_id')
      expect { client.keyless_ssl_configs(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end

    it "lists all keyless ssl configs" do
      result = client.keyless_ssl_configs(zone_id: valid_zone_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_KEYLESS_SSL_LIST))
    end

    it "fails to list details of a keless_ssl_config" do
      expect { client.keyless_ssl_config }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')
      expect { client.keyless_ssl_config(zone_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'zone_id required')
      expect { client.keyless_ssl_config(zone_id: valid_zone_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "lists details of a keyless_ssl_config" do
      result = client.keyless_ssl_config(zone_id: valid_zone_id, id: '4d2844d2ce78891c34d0b6c0535a291e')
      expect(result).to eq(JSON.parse(SUCCESSFULL_KEYLESS_SSL_DETAIL))
    end

    it "fails to update a keyless_ssl_config" do
      expect { client.update_keyless_ssl_config }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect do
        client.update_keyless_ssl_config(zone_id: nil, id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_keyless_ssl_config(zone_id: valid_zone_id, id: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_keyless_ssl_config(zone_id: valid_zone_id, id: 'blah', enabled: 'foo')
      end.to raise_error(RuntimeError, 'enabled must be true||false')
    end

    it "updates a keyless ssl config)" do
      result = client.update_keyless_ssl_config(
        zone_id: valid_zone_id,
        id:      'blah',
        enabled: true,
        host:    'foo.com',
        port:    1234
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_KEYLESS_SSL_UPDATE))
    end

    it "fails to delete a keyless ssl config" do
      expect do
        client.delete_keyless_ssl_config
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect do
        client.delete_keyless_ssl_config(zone_id: nil, id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.delete_keyless_ssl_config(zone_id: valid_zone_id, id: nil)
      end.to raise_error(RuntimeError, 'id required')
    end

    it "deletes a keyless ssl config" do
      result = client.delete_keyless_ssl_config(zone_id: valid_zone_id, id: 'somekeylessid')
      expect(result).to eq(JSON.parse(SUCCESSFULL_KEYLESS_SSL_DELETE))
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
      expect do
        client.create_zone_page_rule
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, targets, actions')

      expect do
        client.create_zone_page_rule(zone_id: nil, targets: ['a'], actions: ['b'])
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.create_zone_page_rule(zone_id: valid_zone_id, targets: 'foo', actions: ['b'])
      end.to raise_error(RuntimeError, 'targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.create_zone_page_rule(zone_id: valid_zone_id, targets: [], actions: ['b'])
      end.to raise_error(RuntimeError, 'targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.create_zone_page_rule(zone_id: valid_zone_id, targets: [{foo: 'bar'}], actions: 'blah')
      end.to raise_error(RuntimeError, 'actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.create_zone_page_rule(zone_id: valid_zone_id, targets: [{foo: 'bar'}], actions: [])
      end.to raise_error(RuntimeError, 'actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.create_zone_page_rule(zone_id: valid_zone_id, targets: [{foo: 'bar'}], actions: [{foo: 'bar'}], status: 'boo')
      end.to raise_error(RuntimeError, 'status must be disabled||active')
    end

    it "creates a custom page rule" do
      result = client.create_zone_page_rule(
        zone_id: valid_zone_id,
        targets: [{foo: 'bar'}],
        actions: [{foo: 'bar'}],
        status:  'active'
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_CREATE))
    end

    it "fails to list all the page rules for a zone" do
      expect do
        client.zone_page_rules
      end.to raise_error(ArgumentError, 'missing keyword: zone_id')

      expect do
        client.zone_page_rules(zone_id: nil)
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.zone_page_rules(zone_id: valid_zone_id, status: 'foo')
      end.to raise_error(RuntimeError, 'status must be either active||disabled')

      expect do
        client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'foo')
      end.to raise_error(RuntimeError, 'order must be either status||priority')

      expect do
        client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'status', direction: 'foo')
      end.to raise_error(RuntimeError, 'direction must be either asc||desc')

      expect do
        client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'status', direction: 'asc', match: 'foo')
      end.to raise_error(RuntimeError, 'match must be either any||all')
    end

    it "lists all the page rules for a zone" do
      result = client.zone_page_rules(zone_id: valid_zone_id, status: 'active', order: 'status', direction: 'asc', match: 'any')
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_LIST))
    end

    it "fails to get details for a page rule" do
      expect { client.zone_page_rule }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')
      expect { client.zone_page_rule(zone_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'zone_id required')
      expect { client.zone_page_rule(zone_id: valid_zone_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets details for a page rule" do
      result = client.zone_page_rule(zone_id: valid_zone_id, id: '9a7806061c88ada191ed06f989cc3dac')
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_DETAIL))
    end

    it "fails to udpate a zone page rule" do
      expect do
        client.update_zone_page_rule
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect do
        client.update_zone_page_rule(zone_id: nil, id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_zone_page_rule(zone_id: valid_zone_id, id: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: 'foo')
      end.to raise_error(RuntimeError, 'targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: [])
      end.to raise_error(RuntimeError, 'targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: [{blah: 'blah'}])
      end.to raise_error(RuntimeError, 'actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: [{blah: 'blah'}], actions: 'foo')
      end.to raise_error(RuntimeError, 'actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule')

      expect do
        client.update_zone_page_rule(zone_id: valid_zone_id, id: 'foobar', targets: [{blah: 'blah'}], actions: [{blah: 'blah'}], status: 'blargh')
      end.to raise_error(RuntimeError, 'status must be disabled||active')
    end

    it "udpates a zone page rule" do
      result = client.update_zone_page_rule(
        zone_id: valid_zone_id,
        id:      '9a7806061c88ada191ed06f989cc3dac',
        targets: [blah: 'blah'],
        actions: [blah: 'blah']
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_DETAIL))
    end

    it "fails to delete a zone page rule" do
      expect { client.delete_zone_page_rule }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect { client.delete_zone_page_rule(zone_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.delete_zone_page_rule(zone_id: valid_zone_id, id: nil)
      end.to raise_error(RuntimeError, 'zone page rule id required')
    end

    it "deletes a zone page rule" do
      result = client.delete_zone_page_rule(zone_id: valid_zone_id, id: '9a7806061c88ada191ed06f989cc3dac')
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_PAGE_RULE_DELETE))
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
      expect { client.zone_rate_limits }.to raise_error(ArgumentError, 'missing keyword: zone_id')
      expect { client.zone_rate_limits(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end

    it "lists rate limits for a zone" do
      result = client.zone_rate_limits(zone_id: valid_zone_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_LIST))
    end

    it "fails to create a zone rate limit" do
      expect do
        client.create_zone_rate_limit
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, match, threshold, period, action')

      expect do
        client.create_zone_rate_limit(zone_id: nil, match: {}, action: {}, threshold: 1, period: 2)
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: 'foo', action: {}, threshold: 1, period: 2)
      end.to raise_error(RuntimeError, 'match must be a match object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: 'foo', threshold: 1, period: 2)
      end.to raise_error(RuntimeError, 'action must be a action object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 'foo', period: 2)
      end.to raise_error(RuntimeError, 'threshold must be between 1 86400')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 0, period: 2)
      end.to raise_error(RuntimeError, 'threshold must be between 1 86400')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 1, period: 'foo')
      end.to raise_error(RuntimeError, 'period must be between 1 86400')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 1, period: 0)
      end.to raise_error(RuntimeError, 'period must be between 1 86400')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 2, period: 1, disabled: 'foo')
      end.to raise_error(RuntimeError, 'disabled must be true || false')

      expect do
        client.create_zone_rate_limit(zone_id: valid_zone_id, match: {}, action: {}, threshold: 2, period: 1, disabled: 'blah')
      end.to raise_error(RuntimeError, 'disabled must be true || false')
    end

    it "creates a zone rate limit" do
      result = client.create_zone_rate_limit(
        zone_id:   valid_zone_id,
        match:     {},
        action:    {},
        threshold: 2,
        disabled:  true,
        period:    30
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_CREATE))
    end

    it "fails to return details for a zone rate limit" do
      expect { client.zone_rate_limit }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')
      expect { client.zone_rate_limit(zone_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'zone_id required')
      expect { client.zone_rate_limit(zone_id: valid_zone_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "returns details for a zone rate limit" do
      result = client.zone_rate_limit(zone_id: valid_zone_id, id: '372e67954025e0ba6aaa6d586b9e0b59')
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_DETAIL))
    end

    it "fails to update a zone rate limit" do
      expect do
        client.update_zone_rate_limit
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, id, match, threshold, period, action')

      expect do
        client.update_zone_rate_limit(zone_id: nil, id: nil, match: nil, threshold: nil, period: nil, action: nil)
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_zone_rate_limit(zone_id: valid_zone_id, id: nil, match: nil, threshold: nil, period: nil, action: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: nil, threshold: nil, period: nil, action: nil)
      end.to raise_error(RuntimeError, 'match must be a match object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')

      expect do
        client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: {}, threshold: 1, period: nil, action: nil)
      end.to raise_error(RuntimeError, 'action must be a action object https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit')

      expect do
        client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: {}, threshold: nil, period: nil, action: nil)
      end.to raise_error(RuntimeError, 'threshold must be between 1 86400')

      expect do
        client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'bar', match: {}, threshold: nil, period: nil, action: nil)
      end.to raise_error(RuntimeError, 'threshold must be between 1 86400')

      expect do
        client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'foobar', match: {}, action: {}, threshold: 50, period: 'foo')
      end.to raise_error(RuntimeError, 'period must be between 1 86400')

      expect do
        client.update_zone_rate_limit(zone_id: valid_zone_id, id: 'foobar', match: {}, action: {}, threshold: 50, period: 200, disabled: 'foo')
      end.to raise_error(RuntimeError, 'disabled must be true || false')
    end

    it "updates a zone rate limit" do
      result = client.update_zone_rate_limit(
        zone_id:     valid_zone_id,
        id:          '372e67954025e0ba6aaa6d586b9e0b59',
        match:       {},
        action:      {},
        threshold:   50,
        period:      100,
        disabled:    false,
        description: 'foo to the bar'
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_UPDATE))
    end

    it "fails to delete a zone ratelimit" do
      expect { client.delete_zone_rate_limit }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect do
        client.delete_zone_rate_limit(zone_id: nil, id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.delete_zone_rate_limit(zone_id: valid_zone_id, id: nil)
      end.to raise_error(RuntimeError, 'zone rate limit id required')
    end

    it "deletes a zone ratelimit" do
      result = client.delete_zone_rate_limit(zone_id: valid_zone_id, id: '372e67954025e0ba6aaa6d586b9e0b59')
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_RATE_LIMITS_DELETE))
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
      expect { client.firewall_access_rules }.to raise_error(ArgumentError, 'missing keyword: zone_id')

      expect { client.firewall_access_rules(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.firewall_access_rules(zone_id: valid_zone_id, mode: 'foo')
      end.to raise_error(RuntimeError, 'mode can only be one of block, challenge, whitelist')

      expect do
        client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'foo')
      end.to raise_error(RuntimeError, 'match can only be one either all || any')

      expect do
        client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'all', scope_type: 'foo')
      end.to raise_error(RuntimeError, 'scope_type can only be one of user, organization, zone')

      expect do
        client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'all', scope_type: 'zone', configuration_target: 'foo')
      end.to raise_error(RuntimeError, 'configuration_target can only be one ["ip", "ip_range", "country"]')

      expect do
        client.firewall_access_rules(zone_id: valid_zone_id, mode: 'block', match: 'all', scope_type: 'zone', configuration_target: 'country', direction: 'foo')
      end.to raise_error(RuntimeError, 'direction must be either asc || desc')
    end

    it "lists firewall access rules" do
      result = client.firewall_access_rules(
        zone_id:              valid_zone_id,
        mode:                 'block',
        match:                'all',
        scope_type:           'zone',
        configuration_target: 'country',
        direction:            'asc'
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_FIREWALL_LIST))
    end

    it "fails to create a firewall access rule" do
      expect do
        client.create_firewall_access_rule
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, mode, configuration')

      expect do
        client.create_firewall_access_rule(zone_id: nil, mode: 'foo', configuration: {})
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.create_firewall_access_rule(zone_id: valid_zone_id, mode: 'foo', configuration: 'foo')
      end.to raise_error(RuntimeError, 'mode must be one of block, challenge, whitlist')

      expect do
        client.create_firewall_access_rule(zone_id: valid_zone_id, mode: 'block', configuration: 'foo')
      end.to raise_error(RuntimeError, 'configuration must be a valid configuration object')

      expect do
        client.create_firewall_access_rule(zone_id: valid_zone_id, mode: 'block', configuration: {foo: 'bar'})
      end.to raise_error(RuntimeError, 'configuration must contain valid a valid target and value')
    end

    it "creates a new firewall access rule" do
      result = client.create_firewall_access_rule(
        zone_id:       valid_zone_id,
        mode:          'block',
        configuration: {target: 'ip', value: '10.1.1.1'}
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_FIREWALL_CREATE_UPDATE))
    end

    it "fails to updates a firewall access rule" do
      expect { client.update_firewall_access_rule }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect do
        client.update_firewall_access_rule(zone_id: nil, id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_firewall_access_rule(zone_id: 'foo', id: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_firewall_access_rule(zone_id: 'foo', id: 'bar', mode: 'foo')
      end.to raise_error(RuntimeError, 'mode must be one of block, challenge, whitlist')
    end

    it "updates a firewall access rule" do
      result = client.update_firewall_access_rule(
        zone_id: valid_zone_id,
        id:      'foo',
        mode:    'block',
        notes:   'foo to the bar'
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_FIREWALL_CREATE_UPDATE))
    end

    it "fails to delete a firewall access rule" do
      expect { client.delete_firewall_access_rule }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect do
        client.delete_firewall_access_rule(zone_id: nil, id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.delete_firewall_access_rule(zone_id: 'foo', id: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.delete_firewall_access_rule(zone_id: 'foo', id: 'bar', cascade: 'cat')
      end.to raise_error(RuntimeError, 'cascade must be one of none, basic, aggressive')
    end

    it "deletes a firewall access rule" do
      result = client.delete_firewall_access_rule(zone_id: valid_zone_id, id: 'foo', cascade: 'basic')
      expect(result).to eq(JSON.parse(SUCCESSFULL_FIREWALL_DELETE))
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
      expect { client.waf_rule_packages }.to raise_error(ArgumentError, 'missing keyword: zone_id')

      expect do
        client.waf_rule_packages(zone_id: nil)
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.waf_rule_packages(zone_id: valid_zone_id, order: 'foo')
      end.to raise_error(RuntimeError, 'order must be either status or name')

      expect do
        client.waf_rule_packages(zone_id: valid_zone_id, order: 'status', direction: 'foo')
      end.to raise_error(RuntimeError, 'direction must be either asc or desc')

      expect do
        client.waf_rule_packages(zone_id: valid_zone_id, order: 'status', direction: 'asc', match: 'foo')
      end.to raise_error(RuntimeError, 'match must be either all or any')
    end

    it "gets waf rule packages" do
      result = client.waf_rule_packages(zone_id: valid_zone_id, order: 'status', direction: 'asc', match: 'any', name: 'bar')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULE_PACKAGES_LIST))
    end

    it "fails to get package details" do
      expect { client.waf_rule_package }.to raise_error(ArgumentError, 'missing keywords: zone_id, id')
      expect { client.waf_rule_package(zone_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'zone_id required')
      expect { client.waf_rule_package(zone_id: valid_zone_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets a waf rule package" do
      result = client.waf_rule_package(zone_id: valid_zone_id, id: 'foo')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULE_PACKAGES_DETAIL))
    end

    it "fails to change the anomoly detection settings of a waf package" do
      expect do
        client.change_waf_rule_anomoly_detection
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, id')

      expect do
        client.change_waf_rule_anomoly_detection(zone_id: nil, id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.change_waf_rule_anomoly_detection(zone_id: valid_zone_id, id: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.change_waf_rule_anomoly_detection(zone_id: valid_zone_id, id: 'foo', sensitivity: 'bar')
      end.to raise_error(RuntimeError, 'sensitivity must be one of high, low, off')

      expect do
        client.change_waf_rule_anomoly_detection(zone_id: valid_zone_id, id: 'foo', sensitivity: 'high', action_mode: 'bar')
      end.to raise_error(RuntimeError, 'action_mode must be one of simulate, block or challenge')
    end

    it "updates a waf rule package" do
      result = client.change_waf_rule_anomoly_detection(
        zone_id:     valid_zone_id,
        id:          'foo',
        sensitivity: 'high',
        action_mode: 'challenge'
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULE_PACKAGES_UPDATE))
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
      expect { client.waf_rule_groups }.to raise_error(ArgumentError, 'missing keywords: zone_id, package_id')

      expect do
        client.waf_rule_groups(zone_id: nil, package_id: 'foo')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.waf_rule_groups(zone_id: valid_zone_id, package_id: nil)
      end.to raise_error(RuntimeError, 'package_id required')

      expect do
        client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'foo')
      end.to raise_error(RuntimeError, 'mode must be one of on or off')

      expect do
        client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'on', order: 'foo')
      end.to raise_error(RuntimeError, 'order must be one of mode or rules_count')

      expect do
        client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'on', order: 'mode', direction: 'foo')
      end.to raise_error(RuntimeError, 'direction must be one of asc or desc')

      expect do
        client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar', mode: 'on', order: 'mode', direction: 'asc', match: 'foo')
      end.to raise_error(RuntimeError, 'match must be either all or any')
    end

    it "lists waf rule groups" do
      result = client.waf_rule_groups(zone_id: valid_zone_id, package_id: 'foobar')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULE_GROUPS_LIST))
    end

    it "fails to get details for a single waf group" do
      expect { client.waf_rule_group }.to raise_error(ArgumentError, 'missing keywords: zone_id, package_id, id')

      expect do
        client.waf_rule_group(zone_id: nil, package_id: 'foo', id: 'bar')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.waf_rule_group(zone_id: valid_zone_id, package_id: nil, id: 'bar')
      end.to raise_error(RuntimeError, 'package_id required')

      expect do
        client.waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: nil)
      end.to raise_error(RuntimeError, 'id required')
    end

    it "gets details of a single waf group" do
      result = client.waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULE_GROUPS_DETAIL))
    end

    it "fails to update a waf group" do
      expect do
        client.update_waf_rule_group
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, package_id, id')

      expect do
        client.update_waf_rule_group(zone_id: nil, package_id: 'foo', id: 'bar')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_waf_rule_group(zone_id: valid_zone_id, package_id: nil, id: 'bar')
      end.to raise_error(RuntimeError, 'package_id required')

      expect do
        client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'blah')
      end.to raise_error(RuntimeError, 'mode must be either on or off')

      expect do
        client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'on')
      end.to_not raise_error

      expect do
        client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'off')
      end.to_not raise_error
    end

    it "updates a waf group" do
      result = client.update_waf_rule_group(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'off')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULE_GROUPS_UPDATE))
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
      expect { client.waf_rules }.to raise_error(ArgumentError, 'missing keywords: zone_id, package_id')

      expect { client.waf_rules(zone_id: nil, package_id: 'foo') }.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.waf_rules(zone_id: valid_zone_id, package_id: nil)
      end.to raise_error(RuntimeError, 'package_id required')

      expect do
        client.waf_rules(zone_id: valid_zone_id, package_id: 'foo', match: 'cat')
      end.to raise_error(RuntimeError, 'match must be either all or any')

      expect do
        client.waf_rules(zone_id: valid_zone_id, package_id: 'foo', order: 'bird')
      end.to raise_error(RuntimeError, 'order must be one of priority, group_id, description')

      expect do
        client.waf_rules(zone_id: valid_zone_id, package_id: 'foo', direction: 'bar')
      end.to raise_error(RuntimeError, 'direction must be either asc or desc')
    end

    it "returns a list of waf rules" do
      result = client.waf_rules(zone_id: valid_zone_id, package_id: 'foo')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULES_LIST))
    end

    it "fails to get a waf rule" do
      expect { client.waf_rule }.to raise_error(ArgumentError, 'missing keywords: zone_id, package_id, id')

      expect do
        client.waf_rule(zone_id: nil, package_id: 'foo', id: 'bar')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.waf_rule(zone_id: valid_zone_id, package_id: nil, id: 'bar')
      end.to raise_error(RuntimeError, 'package_id required')

      expect do
        client.waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: nil)
      end.to raise_error(RuntimeError, 'id required')
    end

    it "gets details for a single waf rule" do
      result = client.waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: 'bar')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULES_DETAIL))
    end

    it "fails to update a waf rule" do
      expect { client.update_waf_rule }.to raise_error(ArgumentError, 'missing keywords: zone_id, package_id, id')

      expect do
        client.update_waf_rule(zone_id: nil, package_id: 'foo', id: 'bar')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_waf_rule(zone_id: valid_zone_id, package_id: nil, id: 'bar')
      end.to raise_error(RuntimeError, 'package_id required')

      expect do
        client.update_waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'boom')
      end.to raise_error(RuntimeError, 'mode must be one of default, disable, simulate, block, challenge, on, off')
    end

    it "updates a waf rule" do
      result = client.update_waf_rule(zone_id: valid_zone_id, package_id: 'foo', id: 'bar', mode: 'on')
      expect(result).to eq(JSON.parse(SUCCESSFULL_WAF_RULES_UPDATE))
    end
  end

  describe "analyze certificate" do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/abc1234/ssl/analyze').
        to_return(response_body(SUCCESSFULL_CERT_ANALYZE))
    end

    it "fails to analyze a certificate" do
      expect { client.analyze_certificate }.to raise_error(ArgumentError, 'missing keyword: zone_id')

      expect { client.analyze_certificate(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.analyze_certificate(zone_id: valid_zone_id, bundle_method: 'foo')
      end.to raise_error(RuntimeError, 'valid bundle methods are ["ubiquitous", "optimal", "force"]')
    end

    it "analyzies a certificate" do
      result = client.analyze_certificate(zone_id: valid_zone_id, certificate: 'bar', bundle_method: 'ubiquitous')
      expect(result).to eq(JSON.parse(SUCCESSFULL_CERT_ANALYZE))
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
      expect { client.certificate_packs }.to raise_error(ArgumentError, 'missing keyword: zone_id')
      expect { client.certificate_packs(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end

    it "lists certificate packs" do
      result = client.certificate_packs(zone_id: valid_zone_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_CERT_PACK_LIST))
    end

    it "fails to order certificate packs" do
      expect { client.order_certificate_packs }.to raise_error(ArgumentError, 'missing keyword: zone_id')

      expect do
        client.order_certificate_packs(zone_id: valid_zone_id, hosts: 'foo')
      end.to raise_error(RuntimeError, 'hosts must be an array of hostnames')
    end

    it "orders certificate packs" do
      result = client.order_certificate_packs(zone_id: valid_zone_id, hosts: ['foobar.com'])
      expect(result).to eq(JSON.parse(SUCCESSFULL_CERT_PACK_ORDER))
    end

    it "fails to update a certificate pack" do
      expect do
        client.update_certificate_pack
      end.to raise_error(ArgumentError, 'missing keywords: zone_id, id, hosts')

      expect do
        client.update_certificate_pack(zone_id: nil, id: 'foo', hosts: ['bar'])
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_certificate_pack(zone_id: valid_zone_id, id: nil, hosts: ['bar'])
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_certificate_pack(zone_id: valid_zone_id, id: 'foo', hosts: [])
      end.to raise_error(RuntimeError, 'hosts must be an array of hosts')
    end

    it "updates a certifiate pack" do
      result = client.update_certificate_pack(zone_id: valid_zone_id, id: 'foo', hosts: ['footothebar'])
      expect(result).to eq(JSON.parse(SUCCESSFULL_CERT_PACK_LIST))
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
      expect { client.ssl_verification }.to raise_error(ArgumentError, 'missing keyword: zone_id')
      expect { client.ssl_verification(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end

    it "verifies a zone" do
      result = client.ssl_verification(zone_id: valid_zone_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_VERIFY_SSL))
      result = client.ssl_verification(zone_id: valid_zone_id, retry_verification: true)
      expect(result).to eq(JSON.parse(SUCCESSFULL_VERIFY_SSL))
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
      expect { client.zone_subscription }.to raise_error(ArgumentError, 'missing keyword: zone_id')
      expect { client.zone_subscription(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end

    it "gets a zone subscription" do
      result = client.zone_subscription(zone_id: valid_zone_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_SUBSCRIPTION))
    end

    it "fails to create a zone subscription" do
      expect { client.create_zone_subscription }.to raise_error(ArgumentError, 'missing keyword: zone_id')

      expect { client.create_zone_subscription(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.create_zone_subscription(zone_id: valid_zone_id, state: 'foo')
      end.to raise_error(RuntimeError, 'state must be one of ["Trial", "Provisioned", "Paid", "AwaitingPayment", "Cancelled", "Failed", "Expired"]')

      expect do
        client.create_zone_subscription(zone_id: valid_zone_id, state: 'Failed', frequency: 'foo')
      end.to raise_error(RuntimeError, 'frequency must be one of ["weekly", "monthly", "quarterly", "yearly"]')
    end

    it "creates a zone subscription" do
      result = client.create_zone_subscription(zone_id: valid_zone_id, state: 'Failed', frequency: 'weekly')
      expect(result).to eq(JSON.parse(SUCCESSFULL_ZONE_SUBSCRIPTION_CREATE))
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
      expect { client.organization }.to raise_error(ArgumentError, 'missing keyword: org_id')
      expect { client.organization(org_id: nil) }.to raise_error(RuntimeError, 'org_id required')
    end

    it "get an org's details" do
      result = client.organization(org_id: valid_zone_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_LIST))
    end

    it "fails to update an org" do
      expect { client.update_organization }.to raise_error(ArgumentError, 'missing keyword: org_id')
      expect { client.update_organization(org_id: nil) }.to raise_error(RuntimeError, 'org_id required')
    end

    it "updates an org" do
      result = client.update_organization(org_id: valid_zone_id, name: 'foobar.com')
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_UPDATE))
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
      expect { client.organization_members }.to raise_error(ArgumentError, 'missing keyword: org_id')
      expect { client.organization_members(org_id: nil) }.to raise_error(RuntimeError, 'org_id required')
    end

    it "returns a list of org members" do
      result = client.organization_members(org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBERS_LIST))
    end

    it "fails to get details for an org member" do
      expect { client.organization_member }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.organization_member(org_id: nil, id: 'bob') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.organization_member(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets the details for an org member" do
      result = client.organization_member(org_id: valid_org_id, id: valid_user_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBER_DETAIL))
    end

    it "fails to updates org member roles" do
      expect do
        client.update_organization_member_roles
      end.to raise_error(ArgumentError, 'missing keywords: org_id, id, roles')

      expect do
        client.update_organization_member_roles(org_id: nil, id: 'bob', roles: nil)
      end.to raise_error(RuntimeError, 'org_id required')

      expect do
        client.update_organization_member_roles(org_id: valid_org_id, id: nil, roles: nil)
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.update_organization_member_roles(org_id: valid_org_id, id: valid_user_id, roles: nil)
      end.to raise_error(RuntimeError, 'roles must be an array of roles')

      expect do
        client.update_organization_member_roles(org_id: valid_org_id, id: valid_user_id, roles: [])
      end.to raise_error(RuntimeError, 'roles cannot be empty')
    end

    it "updates an org members roles" do
      result = client.update_organization_member_roles(org_id: valid_org_id, id: valid_user_id, roles: ['foo', 'bar'])
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBER_UPDATE))
    end

    it "fails to remove an org member" do
      expect { client.remove_org_member }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.remove_org_member(org_id: nil, id: valid_user_id) }.to raise_error(RuntimeError, 'org_id required')
      expect { client.remove_org_member(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "removes and org member" do
      result = client.remove_org_member(org_id: valid_org_id, id: valid_user_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBER_DELETE))
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
      expect do
        client.create_organization_invite
      end.to raise_error(ArgumentError, 'missing keywords: org_id, email, roles')

      expect do
        client.create_organization_invite(org_id: nil, email: valid_user_email, roles: ['foo'], auto_accept: true)
      end.to raise_error(RuntimeError, 'org_id required')

      expect do
        client.create_organization_invite(org_id: valid_org_id, email: nil, roles: ['foo'], auto_accept: true)
      end.to raise_error(RuntimeError, 'email required')

      expect do
        client.create_organization_invite(org_id: valid_org_id, email: valid_user_email, roles: 'foo', auto_accept: true)
      end.to raise_error(RuntimeError, 'roles must be an array of roles')

      expect do
        client.create_organization_invite(org_id: valid_org_id, email: valid_user_email, roles: [], auto_accept: true)
      end.to raise_error(RuntimeError, 'roles cannot be empty')

      expect do
        client.create_organization_invite(org_id: valid_org_id, email: valid_user_email, roles: ['foo', 'bar'], auto_accept: 'foo')
      end.to raise_error(RuntimeError, 'auto_accept must be a boolean value')
    end

    it "creates an organization invite" do
      result = client.create_organization_invite(
        org_id:      valid_org_id,
        email:       valid_user_email,
        roles:       ['foo', 'bar'],
        auto_accept: false
      )

      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_CREATE))
    end

    it "fails to list invites for an organization" do
      expect { client.organization_invites }.to raise_error(ArgumentError, 'missing keyword: org_id')
      expect { client.organization_invites(org_id: nil) }.to raise_error(RuntimeError, 'org_id required')
    end

    it "lists invutes for an organization" do
      result = client.organization_invites(org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITES_LIST))
    end

    it "fails to list details of an organization invite" do
      expect { client.organization_invite }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.organization_invite(org_id: nil, id: 1234) }.to raise_error(RuntimeError, 'org_id required')
      expect { client.organization_invite(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets details of an organization invite" do
      result = client.organization_invite(org_id: valid_org_id, id: 1234)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_DETAIL))
    end

    it "fails to update the roles for an organization invite" do
      expect do
        client.updates_organization_invite_roles
      end.to raise_error(ArgumentError, 'missing keywords: org_id, id, roles')

      expect do
        client.updates_organization_invite_roles(org_id: nil, id: 1234, roles: ['foo'])
      end.to raise_error(RuntimeError, 'org_id required')

      expect do
        client.updates_organization_invite_roles(org_id: valid_org_id, id: nil, roles: ['foo'])
      end.to raise_error(RuntimeError, 'id required')

      expect do
        client.updates_organization_invite_roles(org_id: valid_org_id, id: 1234, roles: nil)
      end.to raise_error(RuntimeError, 'roles must be an array of roles')

      expect do
        client.updates_organization_invite_roles(org_id: valid_org_id, id: 1234, roles: [])
      end.to raise_error(RuntimeError, 'roles cannot be empty')
    end

    it "updates the roles for an organization invite" do
      result = client.updates_organization_invite_roles(org_id: valid_org_id, id: 1234, roles: ['foo', 'bar'])
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_DETAIL))
    end

    it "fails to delete an org invite" do
      expect { client.cancel_organization_invite }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.cancel_organization_invite(org_id: nil, id: nil) }.to raise_error(RuntimeError, 'org_id required')
      expect { client.cancel_organization_invite(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "deletes an organization invites" do
      result = client.cancel_organization_invite(org_id: valid_org_id, id: 1234)
      expect(result).to eq(JSON.parse(SUCCESSFULL_ORG_MEMBERS_INVITE_DELETE))
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
      expect { client.organization_roles }.to raise_error(ArgumentError, "missing keyword: org_id")
      expect { client.organization_roles(org_id: nil) }.to raise_error(RuntimeError, 'org_id required')
    end

    it "lists organization roles" do
      result = client.organization_roles(org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_ROLES))
    end

    it "fails to get details of an organization role" do
      expect { client.organization_role }.to raise_error(ArgumentError, "missing keywords: org_id, id")
      expect { client.organization_role(org_id: nil, id: nil) }.to raise_error(RuntimeError, "org_id required")
      expect { client.organization_role(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, "id required")
    end

    it "gets details of an organization role" do
      result = client.organization_role(org_id: valid_org_id, id: 1234)
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_ROLE_DETAIL))
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

      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_LIST))
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
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_CREATE))
    end

    it "fails to delete an org level access rule" do
      expect { client.delete_org_access_rule }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.delete_org_access_rule(org_id: nil, id: nil) }.to raise_error(RuntimeError, 'org_id required')
      expect { client.delete_org_access_rule(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "deletes an org level access rule" do
      result = client.delete_org_access_rule(org_id: valid_org_id, id: 1234)
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_FIREWALL_RULES_DELETE))
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
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_CREATE))
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
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_LIST))
    end

    it "fails to get details for a railgun" do
      expect { client.org_railgun }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.org_railgun(org_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.org_railgun(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets details for an org railgun" do
      result = client.org_railgun(org_id: valid_org_id, id: 'foobar')
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_DETAILS))
    end

    it "fails to get zones connected to an org railgun" do
      expect { client.org_railgun_connected_zones }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.org_railgun_connected_zones(org_id: nil, id: 'foo') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.org_railgun_connected_zones(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets zones connected to an org railgun" do
      result = client.org_railgun_connected_zones(org_id: valid_org_id, id: 'foobar')
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_ZONES))
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
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_ENABLE))
    end

    it "fails to delete an org railgun" do
      expect { client.delete_org_railgun }.to raise_error(ArgumentError, 'missing keywords: org_id, id')
      expect { client.delete_org_railgun(org_id: nil, id: 'foobar') }.to raise_error(RuntimeError, 'org_id required')
      expect { client.delete_org_railgun(org_id: valid_org_id, id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "deltes an org railgun" do
      result = client.delete_org_railgun(org_id: valid_org_id, id: 'foobar')
      expect(result).to eq(JSON.parse(SUCCESSFUL_ORG_RAILGUN_DELETE))
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
      expect(client.certificates).to eq(JSON.parse(SUCCESSFUL_CERTS))
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

      expect(result).to eq(JSON.parse(SUCCESSFUL_CERTS_CREATE))
    end

    it "fails to get details of a certficiate" do
      expect { client.certificate }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.certificate(id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "gets details for a certificate" do
      result = client.certificate(id: 'somecertid')
      expect(result).to eq(JSON.parse(SUCCESSFUL_CERTS_DETAILS))
    end

    it "fails to revoke a certificate" do
      expect { client.revoke_certificate }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.revoke_certificate(id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    it "revokes a certificate" do
      result = client.revoke_certificate(id: 'somecertid')
      expect(result).to eq(JSON.parse(SUCCESSFUL_CERTS_REVOKE))
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
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_LIST))
    end

    it "lists virtual dns clusters for a org" do
      result = client.virtual_dns_clusters(scope: 'organization', org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_LIST))
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

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_CREATE))
    end

    it "creates an organization dns cluster" do
      result = client.create_virtual_dns_cluster(
        name:                  'foo',
        origin_ips:            ['bar'],
        deprecate_any_request: true,
        scope:                 'organization',
        org_id:                valid_org_id
      )

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_CREATE))
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
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS))
    end

    it "gets details of an organization cluster" do
      result = client.virtual_dns_cluster(id: 'foobar', scope: 'organization', org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS))
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
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DELETE))
    end

    it "deletes a dns an organization's cluster" do
      result = client.delete_virtual_dns_cluster(id: 'foobar', scope: 'organization', org_id: valid_org_id)
      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DELETE))
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

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS))
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

      expect(result).to eq(JSON.parse(SUCCESSFUL_CLUSTER_DETAILS))
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

      expect(result).to eq(JSON.parse(SUCCESSFUL_VIRTUAL_DNS_TABLE))
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

      expect(result).to eq(JSON.parse(SUCCESSFUL_VIRTUAL_DNS_TABLE))
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
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE))
      result = client.get_logs_by_time(zone_id: valid_zone_id, start_time: valid_start_time, end_time: valid_end_time)
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE))
    end

    it "fails to get a log by rayid" do
      expect { client.get_log }.to raise_error(ArgumentError, 'missing keywords: zone_id, ray_id')
    end

    it "get's a log via rayid" do
      result = client.get_log(zone_id: valid_zone_id, ray_id: 'somerayid')
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE))
    end

    it "fails to get logs since a given ray_id" do
      expect { client.get_logs_since }.to raise_error(ArgumentError, 'missing keywords: zone_id, ray_id')

      expect do
        client.get_logs_since(zone_id: valid_zone_id, ray_id: 'foo', end_time: 'bob')
      end.to raise_error(RuntimeError, 'end time must be a valid unix timestamp')
    end

    it "gets logs since a given ray_id" do
      result = client.get_logs_since(zone_id: valid_zone_id, ray_id: 'foo', end_time: valid_end_time, count: 5)
      expect(result).to eq(JSON.parse(SUCCESSFULL_LOG_MESSAGE))
    end
  end
end
