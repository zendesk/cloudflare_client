require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone do
  subject(:client) { CloudflareClient::Zone.new(auth_key: 'somefakekey', email: 'foo@bar.com') }

  describe '#zones' do
    before { stub_request(:get, request_url).to_return(response_body(zone_list)) }

    let(:request_path) { '/zones' }
    let(:request_query) { {page: 1, per_page: 50} }
    let(:zone_list) { create(:zone_list, result_count: 1) }

    it 'lists all zones' do
      expect(client.zones).to eq(zone_list)
    end

    it 'fails to list zones with an invalid status' do
      error_message = "status must be one of #{described_class::VALID_ZONE_STATUSES}"

      expect { client.zones(status: 'foobar') }.to raise_error(RuntimeError, error_message)
    end

    context 'with a zone name' do
      let(:request_query) { {name: name, page: 1, per_page: 50} }
      let(:name) { zone_list[:result].first[:id] }

      it 'lists zones with the given name' do
        expect(client.zones(name: name)).to eq(zone_list)
      end
    end

    context 'with a zone name' do
      let(:request_query) { {status: status, page: 1, per_page: 50} }
      let(:status) { 'active' }

      it 'lists zones with a given status' do
        expect(client.zones(status: status)).to eq(zone_list)
      end
    end
  end

  describe '#create_zone' do
    before { stub_request(:post, request_url).with(body: payload).to_return(response_body(zone_show)) }

    let(:request_path) { '/zones' }
    let(:zone_show) { create(:zone_show) }
    let(:payload) do
      {
        name:         name,
        organization: organization.merge(status: 'active', permissions: %w[#zones:read]),
        jump_start:   jump_start
      }
    end
    let(:name) { zone_show[:result][:name] }
    let(:organization) { {id: 'thisismyorgid', name: 'fish barrel and a smoking gun'} }
    let(:jump_start) { true }

    it 'creates a zone' do
      expect(client.create_zone(name: name, organization: organization)).to eq(zone_show)
    end

    it 'fails to create a zone when missing a name' do
      expect do
        client.create_zone(organization: organization)
      end.to raise_error(ArgumentError, 'missing keyword: :name')

      expect do
        client.create_zone(name: nil, organization: organization)
      end.to raise_error(RuntimeError, 'Zone name required')
    end
  end

  describe '#zone_activation_check' do
    before { stub_request(:put, request_url).to_return(response_body(zone_id_only_response)) }

    let(:zone_id) { zone_id_only_response[:result][:id] }
    let(:request_path) { "/zones/#{zone_id}/activation_check" }
    let(:zone_id_only_response) { create(:zone_id_only_response) }

    it 'requests zone activation check' do
      expect(client.zone_activation_check(zone_id: zone_id)).to eq(zone_id_only_response)
    end

    it 'fails to request a zone activation check' do
      expect { client.zone_activation_check }.to raise_error(ArgumentError, 'missing keyword: :zone_id')
      expect { client.zone_activation_check(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end
  end

  describe '#zone' do
    before { stub_request(:get, request_url).to_return(response_body(zone_show)) }

    let(:zone_id) { zone_show[:result][:id] }
    let(:request_path) { "/zones/#{zone_id}" }
    let(:zone_show) { create(:zone_show) }

    it 'returns details for a single zone' do
      expect(client.zone(zone_id: zone_id)).to eq(zone_show)
    end

    it 'it fails to get an existing zone' do
      expect { client.zone }.to raise_error(ArgumentError, 'missing keyword: :zone_id')
      expect { client.zone(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end
  end

  describe '#edit_zone' do
    before { stub_request(:patch, request_url).with(body: payload).to_return(response_body(zone_show)) }

    let(:request_path) { "/zones/#{zone_id}" }
    let(:zone_show) { create(:zone_show) }
    let(:zone_id) { zone_show[:result][:id] }
    let(:name_servers) { zone_show[:result][:name_servers] }
    let(:payload) { {vanity_name_servers: name_servers} }

    it 'edits and existing zone' do
      result = client.edit_zone(zone_id: zone_id, vanity_name_servers: name_servers).dig(:result, :name_servers)

      expect(result).to eq(name_servers)
    end

    it 'fails to edit an existing zone' do
      expect { client.edit_zone }.to raise_error(ArgumentError, 'missing keyword: :zone_id')
      expect { client.edit_zone(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end
  end

  describe '#purge_zone_cache' do
    before { stub_request(:delete, request_url).with(body: payload).to_return(response_body(zone_id_only_response)) }

    let(:request_path) { "/zones/#{zone_id}/purge_cache" }
    let(:zone_id_only_response) { create(:zone_id_only_response) }
    let(:zone_id) { zone_id_only_response[:result][:id] }
    let(:purge_everything) { true }
    let(:payload) { {purge_everything: purge_everything} }

    it 'purges the entire cache on a zone' do
      expect(client.purge_zone_cache(zone_id: zone_id, purge_everything: purge_everything)).to eq(zone_id_only_response)
    end

    it 'fails to purge the cache on a zone' do
      expect { client.purge_zone_cache }.to raise_error(ArgumentError, 'missing keyword: :zone_id')

      expect { client.purge_zone_cache(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.purge_zone_cache(zone_id: zone_id)
      end.to raise_error(RuntimeError, 'specify a combination tags[], files[] or purge_everything')
    end

    context 'files only' do
      let(:files) { %w[/some_random_file] }
      let(:payload) { {files: files} }

      it 'purges a file from cache on a zone' do
        expect(client.purge_zone_cache(zone_id: zone_id, files: files)).to eq(zone_id_only_response)
      end
    end

    context 'tags only' do
      let(:tags) { %w[tag-to-purge] }
      let(:payload) { {tags: tags} }

      it 'purges a tag from cache on a zone' do
        expect(client.purge_zone_cache(zone_id: zone_id, tags: tags)).to eq(zone_id_only_response)
      end
    end
  end

  describe '#delete_zone' do
    before { stub_request(:delete, request_url).to_return(response_body(zone_id_only_response)) }

    let(:request_path) { "/zones/#{zone_id}" }
    let(:zone_id_only_response) { create(:zone_id_only_response) }
    let(:zone_id) { zone_id_only_response[:result][:id] }

    it 'deletes a zone' do
      expect(client.delete_zone(zone_id: zone_id)).to eq(zone_id_only_response)
    end

    it 'fails to delete a zone' do
      expect { client.delete_zone }.to raise_error(ArgumentError, 'missing keyword: :zone_id')
      expect { client.delete_zone(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end
  end

  describe '#zone_settings' do
    before { stub_request(:get, request_url).to_return(response_body(zone_setting_list)) }

    let(:request_path) { "/zones/#{zone_id}/settings" }
    let(:zone_setting_list) { create(:zone_setting_list) }
    let(:zone_id) { 'abc1234' }

    it 'gets all settings for a zone' do
      expect(client.zone_settings(zone_id: zone_id)).to eq(zone_setting_list)
    end

    it 'fails to get all settings for a zone ' do
      expect { client.zone_settings }.to raise_error(ArgumentError, 'missing keyword: :zone_id')
      expect { client.zone_settings(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')
    end
  end

  describe '#zone_setting' do
    before { stub_request(:get, request_url).to_return(response_body(zone_setting_show)) }

    let(:request_path) { "/zones/#{zone_id}/settings/#{name}" }
    let(:zone_setting_show) { create(:zone_setting_show) }
    let(:zone_id) { 'abc1234' }
    let(:name) { zone_setting_show[:result][:id] }

    it 'gets a setting for a zone' do
      expect(client.zone_setting(zone_id: zone_id, name: name)).to eq(zone_setting_show)
    end

    it 'fails to get settings for a zone' do
      expect { client.zone_setting }.to raise_error(ArgumentError, 'missing keywords: :zone_id, :name')
      
      expect do
        client.zone_setting(zone_id: nil, name: 'response_buffering')
      end.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.zone_setting(zone_id: zone_id, name: 'foobar')
      end.to raise_error(RuntimeError, 'setting_name not valid')
    end
  end

  describe '#update_zone_settings' do
    before { stub_request(:patch, request_url).to_return(response_body(zone_setting_show)) }

    let(:request_path) { "/zones/#{zone_id}/settings" }
    let(:zone_setting_show) { create(:zone_setting_show) }
    let(:zone_id) { 'abc1234' }
    let(:setting) { {name: zone_setting_show[:result][:id], value: zone_setting_show[:result][:value]} }

    it 'updates a setting of the given zone' do
      expect(client.update_zone_settings(zone_id: zone_id, settings: [setting])).to eq(zone_setting_show)
    end

    it 'fails to update zone setting' do
      expect { client.update_zone_settings }.to raise_error(ArgumentError, 'missing keyword: :zone_id')

      expect { client.update_zone_settings(zone_id: nil) }.to raise_error(RuntimeError, 'zone_id required')

      expect do
        client.update_zone_settings(zone_id: zone_id, settings: [name: 'not_a_valid_setting', value: 'yes'])
      end.to raise_error(RuntimeError, 'setting_name "not_a_valid_setting" not valid')
    end
  end
end
