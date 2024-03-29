require 'active_support/core_ext/hash'
require 'active_support/core_ext/time'
require 'webmock/rspec'
require 'single_cov'
require 'factory_bot'
require 'faker'

SingleCov.setup :rspec

Dir[File.expand_path('../shared_examples/*.rb', __FILE__)].each{ |f| require f }
Dir[File.expand_path('../support/*.rb', __FILE__)].each{ |f| require f }

require 'cloudflare_client'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include FactoryBot::Syntax::Methods
  config.before(:suite) { FactoryBot.find_definitions }
end
