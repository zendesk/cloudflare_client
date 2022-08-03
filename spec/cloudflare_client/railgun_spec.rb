require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Railgun do
  subject(:client) { described_class.new(auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:railgun_id) { 'abc1234' }

  describe '#create' do
    before do
      stub_request(:post, 'https://api.cloudflare.com/client/v4/railguns').
        with(body: {name: railgun_name}).
        to_return(response_body(successful_railgun_create))
    end

    let(:successful_railgun_create) { create(:successful_railgun_create) }
    let(:railgun_name) { 'foobar' }

    it 'creates a railgun' do
      expect(client.create(name: railgun_name)).to eq(successful_railgun_create)
    end

    it 'fails to create a railgun with missing name' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keyword: :name')
      expect { client.create(name: nil) }.to raise_error(RuntimeError, 'Railgun name cannot be nil')
    end
  end

  describe '#list' do
    before do
      stub_request(:get, 'https://api.cloudflare.com/client/v4/railguns?direction=desc&page=1&per_page=50').
        to_return(response_body(successful_railgun_list))
    end

    let(:successful_railgun_list) { create(:successful_railgun_list) }

    it 'lists all railguns' do
      expect(client.list).to eq(successful_railgun_list)
    end

    it 'fails to lists all railguns' do
      expect { client.list(direction: 'foo') }.to raise_error(RuntimeError, 'direction must be either desc | asc')
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/railguns/#{railgun_id}").
        to_return(response_body(successful_railgun_show))
    end

    let(:successful_railgun_show) { create(:successful_railgun_show) }

    it 'shows details of the railgun' do
      expect(client.show(id: railgun_id)).to eq(successful_railgun_show)
    end

    it 'fails to get railgun details' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'must provide the id of the railgun')
    end
  end

  describe '#zones' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/railguns/#{railgun_id}/zones").
        to_return(response_body(successful_railgun_zones))
    end

    let(:successful_railgun_zones) { create(:successful_railgun_zones) }

    it 'gets zones connected to a railgun' do
      expect(client.zones(id: railgun_id)).to eq(successful_railgun_zones)
    end

    it 'fails to get zones for a railgun' do
      expect { client.zones }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.zones(id: nil) }.to raise_error(RuntimeError, 'must provide the id of the railgun')
    end
  end

  describe '#enable' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/railguns/#{railgun_id}").
        with(body: {enabled: true}).
        to_return(response_body(successful_railgun_show))
    end

    let(:successful_railgun_show) { create(:successful_railgun_show, result: successful_railgun_result) }
    let(:successful_railgun_result) { create(:successful_railgun_result, enabled: true) }

    it 'enables a railgun' do
      expect(client.enable(id: railgun_id)).to eq(successful_railgun_show)
    end

    it 'fails to enable the status of a railgun' do
      expect { client.enable }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.enable(id: nil) }.to raise_error(RuntimeError, 'must provide the id of the railgun')
    end
  end

  describe '#disable' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/railguns/#{railgun_id}").
        with(body: {enabled: false}).
        to_return(response_body(successful_railgun_show))
    end

    let(:successful_railgun_show) { create(:successful_railgun_show, result: successful_railgun_result) }
    let(:successful_railgun_result) { create(:successful_railgun_result, enabled: false) }

    it 'disables a railgun' do
      expect(client.disable(id: railgun_id)).to eq(successful_railgun_show)
    end

    it 'fails to disable the status of a railgun' do
      expect { client.disable }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.disable(id: nil) }.to raise_error(RuntimeError, 'must provide the id of the railgun')
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/railguns/#{railgun_id}").
        to_return(response_body(successful_railgun_delete))
    end

    let(:successful_railgun_delete) { create(:successful_railgun_delete) }

    it 'deletes a railgun' do
      expect(client.delete(id: railgun_id)).to eq(successful_railgun_delete)
    end

    it 'fails to delete a railgun' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'must provide the id of the railgun')
    end
  end
end
