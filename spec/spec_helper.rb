require_relative 'fixtures/stub_api_responses'
require 'webmock/rspec'
require 'single_cov'
require 'factory_girl'
SingleCov.setup :rspec

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include FactoryGirl::Syntax::Methods
  config.before(:suite) { FactoryGirl.find_definitions }
end
