require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::VirtualDnsCluster::Analytic do
  subject(:client) do
    described_class.new(
      scope:          scope,
      org_id:         org_id,
      virtual_dns_id: virtual_dns_id,
      auth_key:       'somefakekey',
      email:          'foo@bar.com'
    )
  end

  let(:scope) { :user }
  let(:org_id) { nil }
  let(:virtual_dns_id) { 'some_virtual_dns_id' }

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

    context 'when virtual_dns_id is missing' do
      let(:virtual_dns_id) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(StandardError, 'virtual_dns_id required')
      end
    end
  end

  describe '#report' do
    before do
      stub_request(:get, request_url).to_return(response_body(virtual_dns_cluster_analytic_report))
    end

    let(:request_path) { "/user/virtual_dns/#{virtual_dns_id}/dns_analytics/report" }
    let(:request_query) do
      {
        'dimensions[]': dimensions,
        'metrics[]':    metrics,
        since:          since_ts,
        until:          until_ts,
        filters:        filters,
        'sort[]':       sort,
        limit:          limit
      }
    end
    let(:virtual_dns_cluster_analytic_report) { create(:virtual_dns_cluster_analytic_report) }
    let(:query) { virtual_dns_cluster_analytic_report[:query] }
    let(:dimensions) { query[:dimensions] }
    let(:metrics) { query[:metrics] }
    let(:since_ts) { query[:since] }
    let(:until_ts) { query[:until] }
    let(:sort) { query[:sort] }
    let(:filters) { query[:filters] }
    let(:limit) { query[:limit] }

    it 'retrieves summarized metrics over a time period (user)' do
      result = client.report(
        dimensions: dimensions,
        metrics:    metrics,
        since_ts:   since_ts,
        until_ts:   until_ts,
        filters:    filters,
        sort:       sort,
        limit:      limit
      )

      expect(result).to eq(virtual_dns_cluster_analytic_report)
    end

    it 'fails to retrieve summarized metrics over a time period' do
      expect do
        client.report
      end.to raise_error(ArgumentError, 'missing keywords: dimensions, metrics, since_ts, until_ts')

      expect do
        client.report(dimensions: 'foo', metrics: metrics, since_ts: since_ts, until_ts: until_ts)
      end.to raise_error(RuntimeError, 'dimensions must be an array of dimensions')

      expect do
        client.report(dimensions: dimensions, metrics: 'foo', since_ts: since_ts, until_ts: until_ts)
      end.to raise_error(RuntimeError, 'metrics must be an array of metrics')

      expect do
        client.report(dimensions: dimensions, metrics: metrics, since_ts: 'foo', until_ts: until_ts)
      end.to raise_error(RuntimeError, 'since_ts must be a valid iso8601 timestamp')

      expect do
        client.report(dimensions: dimensions, metrics: metrics, since_ts: since_ts, until_ts: 'foo')
      end.to raise_error(RuntimeError, 'until_ts must be a valid iso8601 timestamp')

      expect do
        client.report(dimensions: dimensions, metrics: metrics, since_ts: since_ts, until_ts: until_ts, sort: 'foo')
      end.to raise_error(RuntimeError, 'sort must be an array of sort')

      expect do
        client.report(dimensions: dimensions, metrics: metrics, since_ts: since_ts, until_ts: until_ts, filters: 123)
      end.to raise_error(RuntimeError, 'filters must be a String')

      expect do
        client.report(dimensions: dimensions, metrics: metrics, since_ts: since_ts, until_ts: until_ts, limit: 'foo')
      end.to raise_error(RuntimeError, 'limit must be a Integer')
    end

    context 'for organization' do
      let(:scope) { :organization }
      let(:org_id) { 'some_org_id' }
      let(:request_path) { "/organizations/#{org_id}/virtual_dns/#{virtual_dns_id}/dns_analytics/report" }
      let(:request_query) { {'dimensions[]': dimensions, 'metrics[]': metrics, since: since_ts, until: until_ts} }
      let(:payload) { {name: name, origin_ips: origin_ips} }

      it 'retrieves summarized metrics over a time period (user)' do
        result = client.report(dimensions: dimensions, metrics: metrics, since_ts: since_ts, until_ts: until_ts)

        expect(result).to eq(virtual_dns_cluster_analytic_report)
      end
    end
  end
end
