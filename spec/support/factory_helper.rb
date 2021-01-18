module FactoryHelper
  def self.initializer
    -> { attributes.deep_symbolize_keys }
  end

  def mixed_ip_addresses
    3.times.map { Faker::Internet.ip_v4_address } + 2.times.map { Faker::Internet.ip_v6_address }
  end
end

RSpec.configure { FactoryBot::SyntaxRunner.send(:include, FactoryHelper) }
