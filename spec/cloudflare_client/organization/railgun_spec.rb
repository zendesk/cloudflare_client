require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Organization::Railgun do
  subject(:client) { described_class.new(org_id: org_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:org_id) { SecureRandom.hex(16) }

  it_behaves_like 'initialize for organization features'

  describe '#create' do
    before { stub_request(:post, request_url).to_return(response_body(organization_railgun_show)) }

    let(:organization_railgun_show) { create(:organization_railgun_show) }
    let(:request_path) { "/organizations/#{org_id}/railguns" }
    let(:name) { 'My Railgun' }

    it 'creates an org railgun' do
      expect(client.create(name: name)).to eq(organization_railgun_show)
    end

    it 'fails to create an org railgun' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keyword: :name')
      expect { client.create(name: nil) }.to raise_error(RuntimeError, 'name required')
    end
  end

  describe '#list' do
    before { stub_request(:get, request_url).to_return(response_body(organization_railgun_list)) }

    let(:organization_railgun_list) { create(:organization_railgun_list) }
    let(:request_path) { "/organizations/#{org_id}/railguns" }
    let(:request_query) { {page: page, per_page: per_page, direction: direction} }
    let(:page) { 1 }
    let(:per_page) { 50 }
    let(:direction) { 'desc' }

    it 'lists an orgs railguns' do
      expect(client.list(**request_query)).to eq(organization_railgun_list)
    end

    it 'fails to list an orgs railguns' do
      expect do
        client.list(page: 0)
      end.to raise_error(RuntimeError, 'page must be equal or larger than 1')

      expect do
        client.list(per_page: 4)
      end.to raise_error(RuntimeError, 'per_page must be between 5 and 50')

      expect do
        client.list(per_page: 51)
      end.to raise_error(RuntimeError, 'per_page must be between 5 and 50')

      expect do
        client.list(direction: 'foo')
      end.to raise_error(RuntimeError, "direction must be one of #{described_class::VALID_DIRECTIONS}")
    end
  end

  describe '#show' do
    before { stub_request(:get, request_url).to_return(response_body(organization_railgun_show)) }

    let(:organization_railgun_show) { create(:organization_railgun_show) }
    let(:request_path) { "/organizations/#{org_id}/railguns/#{id}" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }

    it 'gets details for an org railgun' do
      expect(client.show(id: id)).to eq(organization_railgun_show)
    end

    it 'fails to get details for a railgun' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#zones' do
    before { stub_request(:get, request_url).to_return(response_body(organization_railgun_zone_list)) }

    let(:organization_railgun_zone_list) { create(:organization_railgun_zone_list) }
    let(:request_path) { "/organizations/#{org_id}/railguns/#{id}/zones" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }

    it 'gets zones connected to an org railgun' do
      expect(client.zones(id: id)).to eq(organization_railgun_zone_list)
    end

    it 'fails to get zones connected to an org railgun' do
      expect { client.zones }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.zones(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#enable' do
    before do
      stub_request(:patch, request_url).
        with(body: payload).
        to_return(response_body(organization_railgun_show))
    end

    let(:organization_railgun_show) { create(:organization_railgun_show) }
    let(:request_path) { "/organizations/#{org_id}/railguns/#{id}" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }
    let(:payload) { {enabled: true} }

    it 'enables a railgun' do
      expect(client.enable(id: id)).to eq(organization_railgun_show)
    end

    it 'fails to enable a railgun' do
      expect { client.enable }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.enable(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#disable' do
    before do
      stub_request(:patch, request_url).
        with(body: payload).
        to_return(response_body(organization_railgun_show))
    end

    let(:organization_railgun_show) { create(:organization_railgun_show) }
    let(:request_path) { "/organizations/#{org_id}/railguns/#{id}" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }
    let(:payload) { {enabled: false} }

    it 'disables a railgun' do
      expect(client.disable(id: id)).to eq(organization_railgun_show)
    end

    it 'fails to disable a railgun' do
      expect { client.disable }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.disable(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#delete' do
    before { stub_request(:delete, request_url).to_return(response_body(organization_railgun_delete)) }

    let(:organization_railgun_delete) { create(:organization_railgun_delete) }
    let(:request_path) { "/organizations/#{org_id}/railguns/#{id}" }
    let(:id) { SecureRandom.uuid.gsub('-', '') }

    it 'deletes an org railgun' do
      expect(client.delete(id: id)).to eq(organization_railgun_delete)
    end

    it 'fails to delete an org railgun' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: :id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

end
