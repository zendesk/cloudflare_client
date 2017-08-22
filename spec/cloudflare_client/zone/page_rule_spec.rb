require 'spec_helper'

SingleCov.covered!

describe CloudflareClient::Zone::PageRule do
  subject(:client) { described_class.new(zone_id: zone_id, auth_key: 'somefakekey', email: 'foo@bar.com') }

  let(:zone_id) { 'abc1234' }

  it_behaves_like 'initialize for zone features'

  describe '#create' do
    before do
      stub_request(:post, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/pagerules").
        with(body: payload).
        to_return(response_body(page_rule_show))
    end

    let(:page_rule_show) { create(:page_rule_show) }
    let(:targets) { create_list(:page_rule_target, 1) }
    let(:actions) { create_list(:page_rule_action, 1) }
    let(:status) { 'active' }
    let(:priority) { 1 }
    let(:payload) { {targets: targets, actions: actions, priority: priority, status: status} }

    it 'creates a custom page rule' do
      expect(client.create(targets: targets, actions: actions, status: status)).to eq(page_rule_show)
    end

    it 'fails to create a custom page rule' do
      expect { client.create }.to raise_error(ArgumentError, 'missing keywords: targets, actions')

      expect do
        client.create(targets: 'foo', actions: actions)
      end.to raise_error(RuntimeError, "targets must be an array of targets #{described_class::DOC_URL}")

      expect do
        client.create(targets: [], actions: actions)
      end.to raise_error(RuntimeError, "targets must be an array of targets #{described_class::DOC_URL}")

      expect do
        client.create(targets: targets, actions: 'blah')
      end.to raise_error(RuntimeError, "actions must be an array of actions #{described_class::DOC_URL}")

      expect do
        client.create(targets: targets, actions: [])
      end.to raise_error(RuntimeError, "actions must be an array of actions #{described_class::DOC_URL}")

      expect do
        client.create(targets: targets, actions: actions, status: 'boo')
      end.to raise_error(RuntimeError, "status must be one of #{described_class::VALID_STATUSES}")
    end
  end

  describe '#list' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/pagerules?direction=#{direction}&match=#{match}&order=#{order}&status=#{status}").
        to_return(response_body(page_rule_list))
    end

    let(:page_rule_list) { create(:page_rule_list) }
    let(:status) { 'active' }
    let(:order) { 'status' }
    let(:direction) { 'asc' }
    let(:match) { 'any' }

    it 'lists all the page rules for a zone' do
      expect(client.list(status: status, order: order, direction: direction, match: match)).to eq(page_rule_list)
    end

    it 'fails to list all the page rules for a zone' do
      expect do
        client.list(status: 'foo')
      end.to raise_error(RuntimeError, "status must be one of #{described_class::VALID_STATUSES}")

      expect do
        client.list(order: 'foo')
      end.to raise_error(RuntimeError, "order must be one of #{described_class::VALID_ORDERS}")

      expect do
        client.list(direction: 'foo')
      end.to raise_error(RuntimeError, "direction must be one of #{described_class::VALID_DIRECTIONS}")

      expect do
        client.list(match: 'foo')
      end.to raise_error(RuntimeError, "match must be one of #{described_class::VALID_MATCHES}")
    end
  end

  describe '#show' do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/pagerules/#{id}").
        to_return(response_body(page_rule_show))
    end

    let(:page_rule_show) { create(:page_rule_show) }
    let(:id) { '9a7806061c88ada191ed06f989cc3dac' }

    it 'gets details for a page rule' do
      result = client.show(id: '9a7806061c88ada191ed06f989cc3dac')
      expect(result).to eq(page_rule_show)
    end

    it 'fails to get details for a page rule' do
      expect { client.show }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.show(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end

  describe '#update' do
    before do
      stub_request(:patch, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/pagerules/#{id}").
        with(body: payload).
        to_return(response_body(page_rule_show))
    end

    let(:page_rule_show) { create(:page_rule_show, result: page_rule_result) }
    let(:page_rule_result) { create(:page_rule_result, targets: targets, actions: actions) }
    let(:targets) { create_list(:page_rule_target, 1) }
    let(:actions) { create_list(:page_rule_action, 1) }
    let(:status) { 'disabled' }
    let(:priority) { 1 }
    let(:id) { '9a7806061c88ada191ed06f989cc3dac' }
    let(:payload) { {targets: targets, actions: actions, priority: priority, status: status} }

    it 'udpates a zone page rule' do
      expect(client.update(id: id, targets: targets, actions: actions)).to eq(page_rule_show)
    end

    it 'fails to udpate a zone page rule' do
      expect { client.update }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.update(id: nil) }.to raise_error(RuntimeError, 'id required')

      expect do
        client.update(id: id, targets: 'foo')
      end.to raise_error(RuntimeError, "targets must be an array of targets #{described_class::DOC_URL}")

      expect do
        client.update(id: id, targets: [])
      end.to raise_error(RuntimeError, "targets must be an array of targets #{described_class::DOC_URL}")

      expect do
        client.update(id: id, targets: targets)
      end.to raise_error(RuntimeError, "actions must be an array of actions #{described_class::DOC_URL}")

      expect do
        client.update(id: id, targets: targets, actions: 'foo')
      end.to raise_error(RuntimeError, "actions must be an array of actions #{described_class::DOC_URL}")

      expect do
        client.update(id: id, targets: targets, actions: actions, status: 'blargh')
      end.to raise_error(RuntimeError, "status must be one of #{described_class::VALID_STATUSES}")
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/#{zone_id}/pagerules/#{id}").
        to_return(response_body(page_rule_delete))
    end

    let(:page_rule_delete) { create(:page_rule_delete) }
    let(:id) { '9a7806061c88ada191ed06f989cc3dac' }

    it 'deletes a zone page rule' do
      expect(client.delete(id: id)).to eq(page_rule_delete)
    end

    it 'fails to delete a zone page rule' do
      expect { client.delete }.to raise_error(ArgumentError, 'missing keyword: id')
      expect { client.delete(id: nil) }.to raise_error(RuntimeError, 'id required')
    end
  end
end
