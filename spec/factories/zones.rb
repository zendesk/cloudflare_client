FactoryGirl.define do
  factory :zones, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :successful_zone_query do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Internet.domain_name }
      development_mode 7200
      original_name_servers %w[ns1.originaldnshost.com ns2.originaldnshost.com]
      original_registrar { Faker::Company.name }
      original_dnshost { Faker::Company.name }
      created_on { Time.now.utc.iso8601(5) }
      modified_on { Time.now.utc.iso8601(5) }
      name_servers { rand(2..4).times.map { Faker::Internet.domain_name } }
      owner { create(:zone_owner) }
      permissions %w[#zone:read #zone:edit]
      plan { create(:zone_plan) }
      plan_pending { create(:zone_plan) }
      status 'active'
      paused false
      type 'full'
      checked_on { Time.now.utc.iso8601(5) }
    end

    factory :zone_owner do
      id { SecureRandom.uuid.gsub('-', '') }
      email { Faker::Internet.email }
      owner_type 'user'
    end

    factory :zone_plan do
      id { SecureRandom.uuid.gsub('-', '') }
      name 'Pro Plan'
      price { Faker::Commerce.price }
      currency 'USD'
      frequency 'monthly'
      legacy_id 'pro'
      is_subscribed true
      can_subscribe true
    end

    factory :failed_zone_query do
      success false
      errors { create_list(:zone_query_error, rand(1..3)) }
      messages []
      result nil
    end

    factory :zone_query_error do
      code { Faker::Number.number(4) }
      message { Faker::Hacker.say_something_smart }
    end

    factory :successful_zone_delete do
      success true
      errors []
      messages []
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end

    factory :successful_zone_edit do
      success true
      errors []
      messages []
      result { create(:successful_zone_query) }
    end

    factory :successful_zone_cache_purge do
      success true
      errors []
      messages []
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end
  end
end
