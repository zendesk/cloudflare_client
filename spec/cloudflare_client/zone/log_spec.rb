require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::Log do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }
  let(:zone_log) { create(:zone_log) }

  it_behaves_like 'initialize for zone features'

  describe '#list_by_time' do
    before { stub_request(:get, request_url).to_return(response_body(zone_log)) }

    let(:request_path) { "/zones/#{zone_id}/logs/requests" }
    let(:request_query) { {start: start_time} }
    let(:start_time) { Time.now.utc.advance(hours: -1).to_i }

    it 'list logs via start_time' do
      # note, these are raw not json encoded
      expect(client.list_by_time(start_time: start_time)).to eq(zone_log)
    end

    it 'fails to get logs via timestamps' do
      expect { client.list_by_time }.to raise_error(ArgumentError, 'missing keyword: start_time')
      expect { client.list_by_time(start_time: nil) }.to raise_error(RuntimeError, 'start_time required')
    end

    it 'fails with invalid timestamps' do
      expect do
        client.list_by_time(start_time: 'foo')
      end.to raise_error(RuntimeError, 'start_time must be a valid unix timestamp')

      expect do
        client.list_by_time(start_time: start_time, end_time: 'foo')
      end.to raise_error(RuntimeError, 'end_time must be a valid unix timestamp')
    end

    context 'with end_time' do
      let(:request_query) { {start: start_time, end: end_time} }
      let(:end_time) { Time.now.utc.to_i }

      it 'list logs via timestamps' do
        # note, these are raw not json encoded
        expect(client.list_by_time(start_time: start_time, end_time: end_time)).to eq(zone_log)
      end
    end

    context 'with count' do
      let(:request_query) { {start: start_time, count: count} }
      let(:count) { rand(1..100) }

      it 'list logs via start_time and count' do
        # note, these are raw not json encoded
        expect(client.list_by_time(start_time: start_time, count: count)).to eq(zone_log)
      end
    end
  end

  describe '#show' do
    before { stub_request(:get, request_url).to_return(response_body(zone_log)) }

    let(:request_path) { "/zones/#{zone_id}/logs/requests/#{ray_id}" }
    let(:ray_id) { 'some_ray_id' }

    it 'show a log via ray_id' do
      expect(client.show(ray_id: ray_id)).to eq(zone_log)
    end

    it 'fails to show a log by ray_id' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: ray_id')
      expect { client.show(ray_id: nil) }.to raise_error(RuntimeError, 'ray_id required')
    end
  end

  describe '#list_since' do
    before { stub_request(:get, request_url).to_return(response_body(zone_log)) }

    let(:request_path) { "/zones/#{zone_id}/logs/requests/#{ray_id}" }
    let(:request_query) { {start_id: ray_id, end: end_time, count: count} }
    let(:ray_id) { 'some_ray_id' }
    let(:end_time) { Time.now.utc.to_i }
    let(:count) { rand(1..5) }

    it 'lists logs since a given ray_id' do
      expect(client.list_since(ray_id: ray_id, end_time: end_time, count: count)).to eq(zone_log)
    end

    it 'fails to list logs since a given ray_id' do
      expect { client.list_since }.to raise_error(ArgumentError, 'missing keyword: ray_id')

      expect do
        client.list_since(ray_id: ray_id, end_time: 'foo')
      end.to raise_error(RuntimeError, 'end_time must be a valid unix timestamp')
    end
  end
end
