require 'spec_helper'
require 'zendesk_cloudflare/zone'

SingleCov.covered!

describe CloudflareClient::Zone do
  subject(:client) { CloudflareClient::Zone.new(auth_key: 'somefakekey', email: 'foo@bar.com') }

  before do
    stub_request(:post, 'https://api.cloudflare.com/client/v4/zones').
      to_return(response_body(successful_zone_query))
    stub_request(:put, 'https://api.cloudflare.com/client/v4/zones/1234abcd/activation_check').
      to_return(response_body(successful_zone_query))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones?page=1&per_page=50').
      to_return(response_body(successful_zone_query))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones?name=testzonename.com&page=1&per_page=50').
      to_return(response_body(successful_zone_query))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/1234abc').
      to_return(response_body(successful_zone_query))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/shouldfail').
      to_return(response_body(failed_zone_query).merge(status: 400))
    stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234').
      to_return(response_body(successful_zone_edit))
    stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234').
      to_return(response_body(successful_zone_delete))
    stub_request(:delete, 'https://api.cloudflare.com/client/v4/zones/abc1234/purge_cache').
      to_return(response_body(successful_zone_cache_purge))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/settings').
      to_return(response_body(successful_zone_query))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/').
      to_return(response_body(successful_zone_query))
    stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/abc1234/settings/always_online').
      to_return(response_body(successful_zone_query))
    stub_request(:patch, 'https://api.cloudflare.com/client/v4/zones/abc1234/settings').
      to_return(response_body(successful_zone_edit))
  end

  let(:successful_zone_query) { create(:successful_zone_query) }
  let(:failed_zone_query) { create(:failed_zone_query) }
  let(:successful_zone_edit) { create(:successful_zone_edit) }
  let(:successful_zone_delete) { create(:successful_zone_delete) }
  let(:successful_zone_cache_purge) { create(:successful_zone_cache_purge) }
  let(:valid_zone_id) { 'abc1234' }

  it 'creates a zone' do
    result = client.create_zone(
      name:         'testzone.com',
      organization: {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'}
    )

    expect(result).to eq(successful_zone_query)
  end

  it 'fails to create a zone when missing a name' do
    expect do
      client.create_zone(organization: {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'})
    end.to raise_error(ArgumentError, 'missing keyword: name')

    expect do
      client.create_zone(name: nil, organization: {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'})
    end.to raise_error(RuntimeError, 'Zone name required')
  end

  it 'fails to delete a zone' do
    expect { client.delete_zone }.to raise_error(ArgumentError, 'missing keyword: zone_id')
    expect { client.delete_zone(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
  end

  it 'deletes a zone' do
    result = client.delete_zone(zone_id: valid_zone_id)
    expect(result).to eq(successful_zone_delete)
  end

  it 'fails to request a zone activation check' do
    expect { client.zone_activation_check }.to raise_error(ArgumentError, 'missing keyword: zone_id')
    expect { client.zone_activation_check(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
  end

  it 'requests zone activcation check succeedes' do
    client.zone_activation_check(zone_id: '1234abcd')
  end

  it 'lists all zones' do
    result = client.zones
    expect(result).to eq(successful_zone_query)
  end

  it 'lists zones with a given name' do
    result = client.zones(name: 'testzonename.com')
    expect(result).to eq(successful_zone_query)
  end

  it 'fails lists zones with an invalid status' do
    statuses      = ['active', 'pending', 'initializing', 'moved', 'deleted', 'deactivated', 'read only']
    error_message = "status must be one of #{statuses}"
    expect { client.zones(status: 'foobar') }.to raise_error(RuntimeError, error_message)
  end

  it 'lists zones with a given status' do
    result = client.zones(status: 'active')
    expect(result).to eq(successful_zone_query)
  end

  it 'it fails to get an existing zone' do
    expect { client.zone }.to raise_error(ArgumentError, 'missing keyword: zone_id')
    expect { client.zone(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
  end

  it 'returns details for a single zone' do
    result = client.zone(zone_id: '1234abc')
    expect(result).to eq(successful_zone_query)
  end

  it 'fails to edit an existing zone' do
    expect { client.edit_zone }.to raise_error(ArgumentError, 'missing keyword: zone_id')
    expect { client.edit_zone(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
  end

  it 'edits and existing zone' do
    name_servers = successful_zone_edit['result']['name_servers']
    result       = client.
      edit_zone(zone_id: valid_zone_id, vanity_name_servers: name_servers).
      dig('result', 'name_servers')

    expect(result).to eq(name_servers)
  end

  it 'fails to purge the cache on a zone' do
    expect { client.purge_zone_cache }.to raise_error(ArgumentError, 'missing keyword: zone_id')

    expect { client.purge_zone_cache(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')

    expect do
      client.purge_zone_cache(zone_id: valid_zone_id)
    end.to raise_error(RuntimeError, 'specify a combination tags[], files[] or purge_everything')
  end

  it 'succeedes in purging the entire cache on a zone' do
    result = client.purge_zone_cache(zone_id: valid_zone_id, purge_everything: true)
    expect(result).to eq(successful_zone_cache_purge)
  end

  it 'succeedes in purging a file from cache on a zone' do
    result = client.purge_zone_cache(zone_id: valid_zone_id, files: ['/some_random_file'])
    expect(result).to eq(successful_zone_cache_purge)
  end

  it 'succeedes in purging a tag from cache on a zone' do
    result = client.purge_zone_cache(zone_id: valid_zone_id, tags: ['tag-to-purge'])
    expect(result).to eq(successful_zone_cache_purge)
  end

  it 'fails to get all settings for a zone ' do
    expect { client.zone_settings }.to raise_error(ArgumentError, 'missing keyword: zone_id')
    expect { client.zone_settings(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
  end

  it 'gets all settings for a zone' do
    result = client.zone_settings(zone_id: valid_zone_id)
    expect(result).to eq(successful_zone_query)
  end

  it 'fails to get settings for a zone' do
    expect { client.zone_setting }.to raise_error(ArgumentError, 'missing keywords: zone_id, name')

    expect do
      client.zone_setting(zone_id: nil, name: 'response_buffering')
    end.to raise_error(RuntimeError, 'zone_id required')

    expect do
      client.zone_setting(zone_id: valid_zone_id, name: 'foobar')
    end.to raise_error(RuntimeError, 'setting_name not valid')
  end

  it 'gets a setting for a zone' do
    client.zone_setting(zone_id: valid_zone_id, name: 'always_online')
  end

  it 'fails to update zone setting' do
    expect { client.update_zone_settings }.to raise_error(ArgumentError, 'missing keyword: zone_id')

    expect { client.update_zone_settings(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')

    expect do
      client.update_zone_settings(zone_id: 'abc1234', settings: [name: 'not_a_valid_setting', value: 'yes'])
    end.to raise_error(RuntimeError, 'setting_name "not_a_valid_setting" not valid')
  end

  it "updates a zone's setting" do
    client.update_zone_settings(zone_id: 'abc1234', settings: [name: 'always_online', value: 'yes'])
  end

  def response_body(body)
    {body: body.to_json, headers: {'Content-Type': 'application/json'}}
  end
end
