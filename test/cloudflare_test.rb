require_relative "test_helper"

SingleCov.covered!

require_relative "../lib/cloudflare.rb"

describe Cloudflare::Zone do
  it "initializes correctly" do
    Cloudflare::Zone.new(zone_id: "somezoneid", auth_key: "auth_key", email: "foo@bar.com")
  end
  it "raises when missing auth_key" do
    assert_raises(RuntimeError) { Cloudflare::Zone.new() }
  end
  it "raises when missing auth_email" do
    assert_raises(RuntimeError) { Cloudflare::Zone.new(auth_key: "somefakekey") }
  end
end
