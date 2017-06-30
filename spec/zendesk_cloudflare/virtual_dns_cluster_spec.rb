require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered!

describe CloudflareClient::VirtualDnsCluster do
  subject(:client) { described_class.new(scope: scope, org_id: org_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:scope) { :user }
  let(:org_id) { nil }

  describe '#initialize' do
    it 'returns a client instance for a user' do
      expect { subject }.to_not raise_error
      expect(subject).to be_a(described_class)
      expect(subject.uri_prefix).to eq('/user')
    end

    context 'when scope is missing' do
      let(:scope) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(StandardError, "scope must be one of #{described_class::VALID_SCOPES}")
      end
    end

    context 'when scope is :organization' do
      let(:scope) { :organization }
      let(:org_id) { 'some_org_id' }

      it 'returns a client instance for an organization' do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(described_class)
        expect(subject.uri_prefix).to eq("/organizations/#{org_id}")
      end

      context 'when org_id is missing' do
        let(:org_id) { nil }

        it 'raises error' do
          expect { subject }.to raise_error(StandardError, 'org_id required')
        end
      end
    end
  end

  describe '#list' do
    before { stub_request(:get, request_url).to_return(response_body(virtual_dns_cluster_list)) }

    let(:virtual_dns_cluster_list) { create(:virtual_dns_cluster_list) }
    let(:request_path) { '/user/virtual_dns' }

    it 'lists virtual dns clusters for a user' do
      expect(client.list).to eq(virtual_dns_cluster_list)
    end

    context 'for organization' do
      let(:scope) { :organization }
      let(:org_id) { 'some_org_id' }
      let(:request_path) { "/organizations/#{org_id}/virtual_dns" }

      it 'lists virtual dns clusters for a user' do
        expect(client.list).to eq(virtual_dns_cluster_list)
      end
    end
  end

  describe '#create' do
    before { stub_request(:post, request_url).with(body: payload).to_return(response_body(virtual_dns_cluster_show)) }

    let(:virtual_dns_cluster_show) { create(:virtual_dns_cluster_show, result: result) }
    let(:result) { create(:virtual_dns_cluster_result) }
    let(:request_path) { '/user/virtual_dns' }
    let(:name) { result[:name] }
    let(:origin_ips) { result[:origin_ips] }
    let(:minimum_cache_ttl) { result[:minimum_cache_ttl] }
    let(:maximum_cache_ttl) { result[:maximum_cache_ttl] }
    let(:deprecate_any_requests) { result[:deprecate_any_requests] }
    let(:ratelimit) { result[:ratelimit] }
    let(:payload) do
      {
        name:                  name,
        origin_ips:            origin_ips,
        minimum_cache_ttl:     minimum_cache_ttl,
        maximum_cache_ttl:     maximum_cache_ttl,
        deprecate_any_request: deprecate_any_requests,
        ratelimit:             ratelimit
      }
    end

    it 'creates a user dns cluster' do
      expect(client.create(payload)).to eq(virtual_dns_cluster_show)
    end

    it 'fails to create a dns cluster' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: name, origin_ips')
      expect { client.create(name: nil, origin_ips: origin_ips) }.to raise_error(RuntimeError, 'name required')

      expect do
        client.create(name: name, origin_ips: 'foo')
      end.to raise_error(RuntimeError, 'origin_ips must be an array of origin_ips')

      expect do
        client.create(name: name, origin_ips: [])
      end.to raise_error(RuntimeError, 'origin_ips must be an array of origin_ips')

      expect do
        client.create(name: name, origin_ips: origin_ips, minimum_cache_ttl: 29)
      end.to raise_error(RuntimeError, 'minimum_cache_ttl must be between 30 and 36000')

      expect do
        client.create(name: name, origin_ips: origin_ips, minimum_cache_ttl: 36001)
      end.to raise_error(RuntimeError, 'minimum_cache_ttl must be between 30 and 36000')

      expect do
        client.create(name: name, origin_ips: origin_ips, maximum_cache_ttl: 29)
      end.to raise_error(RuntimeError, 'maximum_cache_ttl must be between 30 and 36000')

      expect do
        client.create(name: name, origin_ips: origin_ips, maximum_cache_ttl: 36001)
      end.to raise_error(RuntimeError, 'maximum_cache_ttl must be between 30 and 36000')

      expect do
        client.create(name: name, origin_ips: origin_ips, deprecate_any_request: 'foo')
      end.to raise_error(RuntimeError, "deprecate_any_request must be one of #{[true, false]}")

      expect do
        client.create(name: name, origin_ips: origin_ips, ratelimit: -1)
      end.to raise_error(RuntimeError, 'ratelimit must be between 0 and 100000000')

      expect do
        client.create(name: name, origin_ips: origin_ips, ratelimit: 100000001)
      end.to raise_error(RuntimeError, 'ratelimit must be between 0 and 100000000')
    end

    context 'for organization' do
      let(:scope) { :organization }
      let(:org_id) { 'some_org_id' }
      let(:request_path) { "/organizations/#{org_id}/virtual_dns" }
      let(:payload) { {name: name, origin_ips: origin_ips} }

      it 'creates a user dns cluster' do
        expect(client.create(payload)).to eq(virtual_dns_cluster_show)
      end
    end
  end

  describe '#show' do
    before { stub_request(:get, request_url).to_return(response_body(virtual_dns_cluster_show)) }

    let(:virtual_dns_cluster_show) { create(:virtual_dns_cluster_show, result: result) }
    let(:result) { create(:virtual_dns_cluster_result) }
    let(:request_path) { "/user/virtual_dns/#{id}" }
    let(:id) { result[:id] }

    it 'gets details of a user cluster' do
      expect(client.show(id: id)).to eq(virtual_dns_cluster_show)
    end

    it 'fails to get deatails of a cluster' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    context 'for organization' do
      let(:scope) { :organization }
      let(:org_id) { 'some_org_id' }
      let(:request_path) { "/organizations/#{org_id}/virtual_dns/#{id}" }

      it 'gets details of a user cluster' do
        expect(client.show(id: id)).to eq(virtual_dns_cluster_show)
      end
    end
  end

  describe '#delete' do
    before { stub_request(:delete, request_url).to_return(response_body(virtual_dns_cluster_delete)) }

    let(:virtual_dns_cluster_delete) { create(:virtual_dns_cluster_delete) }
    let(:request_path) { "/user/virtual_dns/#{id}" }
    let(:id) { virtual_dns_cluster_delete[:result][:id] }

    it 'deletes a dns user cluster' do
      expect(client.delete(id: id)).to eq(virtual_dns_cluster_delete)
    end

    it 'fails to delete a virtual dns cluster' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end

    context 'for organization' do
      let(:scope) { :organization }
      let(:org_id) { 'some_org_id' }
      let(:request_path) { "/organizations/#{org_id}/virtual_dns/#{id}" }

      it 'deletes a dns user cluster' do
        expect(client.delete(id: id)).to eq(virtual_dns_cluster_delete)
      end
    end
  end

  describe '#update' do
    before { stub_request(:patch, request_url).with(body: payload).to_return(response_body(virtual_dns_cluster_show)) }

    let(:virtual_dns_cluster_show) { create(:virtual_dns_cluster_show, result: result) }
    let(:result) { create(:virtual_dns_cluster_result) }
    let(:request_path) { "/user/virtual_dns/#{id}" }
    let(:id) { result[:id] }
    let(:name) { result[:name] }
    let(:origin_ips) { result[:origin_ips] }
    let(:minimum_cache_ttl) { result[:minimum_cache_ttl] }
    let(:maximum_cache_ttl) { result[:maximum_cache_ttl] }
    let(:deprecate_any_requests) { result[:deprecate_any_requests] }
    let(:ratelimit) { result[:ratelimit] }
    let(:payload) do
      {
        name:                  name,
        origin_ips:            origin_ips,
        minimum_cache_ttl:     minimum_cache_ttl,
        maximum_cache_ttl:     maximum_cache_ttl,
        deprecate_any_request: deprecate_any_requests,
        ratelimit:             ratelimit
      }
    end

    it 'updates a user dns cluster' do
      expect(client.update(payload.merge(id: id))).to eq(virtual_dns_cluster_show)
    end

    it 'fails to update a dns cluster' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, origin_ips: 'foo')
      end.to raise_error(RuntimeError, 'origin_ips must be an array of origin_ips')

      expect do
        client.update(id: id, name: name, origin_ips: [])
      end.to raise_error(RuntimeError, 'origin_ips must be an array of origin_ips')

      expect do
        client.update(id: id, name: name, origin_ips: origin_ips, minimum_cache_ttl: 29)
      end.to raise_error(RuntimeError, 'minimum_cache_ttl must be between 30 and 36000')

      expect do
        client.update(id: id, name: name, origin_ips: origin_ips, minimum_cache_ttl: 36001)
      end.to raise_error(RuntimeError, 'minimum_cache_ttl must be between 30 and 36000')

      expect do
        client.update(id: id, name: name, origin_ips: origin_ips, maximum_cache_ttl: 29)
      end.to raise_error(RuntimeError, 'maximum_cache_ttl must be between 30 and 36000')

      expect do
        client.update(id: id, name: name, origin_ips: origin_ips, maximum_cache_ttl: 36001)
      end.to raise_error(RuntimeError, 'maximum_cache_ttl must be between 30 and 36000')

      expect do
        client.update(id: id, name: name, origin_ips: origin_ips, deprecate_any_request: 'foo')
      end.to raise_error(RuntimeError, "deprecate_any_request must be one of #{[true, false]}")

      expect do
        client.update(id: id, name: name, origin_ips: origin_ips, ratelimit: -1)
      end.to raise_error(RuntimeError, 'ratelimit must be between 0 and 100000000')

      expect do
        client.update(id: id, name: name, origin_ips: origin_ips, ratelimit: 100000001)
      end.to raise_error(RuntimeError, 'ratelimit must be between 0 and 100000000')
    end

    context 'for organization' do
      let(:scope) { :organization }
      let(:org_id) { 'some_org_id' }
      let(:request_path) { "/organizations/#{org_id}/virtual_dns/#{id}" }

      it 'updates a user dns cluster' do
        expect(client.update(payload.merge(id: id))).to eq(virtual_dns_cluster_show)
      end
    end
  end
end
