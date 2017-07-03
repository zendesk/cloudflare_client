# rubocop:disable LineLength

require 'spec_helper'
require 'zendesk_cloudflare'

SingleCov.covered! uncovered: 4

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
end
