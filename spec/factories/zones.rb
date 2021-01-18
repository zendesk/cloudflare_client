FactoryBot.define do
  factory :zones, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :zone_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:zone_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :zone_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:zone_result) }
    end

    factory :zone_id_only_response do
      success { true }
      errors { [] }
      messages { [] }
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end

    factory :zone_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Internet.domain_name }
      development_mode { 7200 }
      original_name_servers { %w[ns1.originaldnshost.com ns2.originaldnshost.com] }
      original_registrar { Faker::Company.name }
      original_dnshost { Faker::Company.name }
      created_on { Time.now.utc.iso8601(5) }
      modified_on { Time.now.utc.iso8601(5) }
      name_servers { rand(2..4).times.map { Faker::Internet.domain_name } }
      owner { create(:zone_owner) }
      permissions { %w[#zone:read #zone:edit] }
      plan { create(:zone_plan) }
      plan_pending { create(:zone_plan) }
      status { 'active' }
      paused { false }
      type { 'full' }
      checked_on { Time.now.utc.iso8601(5) }
    end

    factory :zone_owner do
      id { SecureRandom.uuid.gsub('-', '') }
      email { Faker::Internet.email }
      owner_type { 'user' }
    end

    factory :zone_plan do
      id { SecureRandom.uuid.gsub('-', '') }
      name { 'Pro Plan' }
      price { Faker::Commerce.price }
      currency { 'USD' }
      frequency { 'monthly' }
      legacy_id { 'pro' }
      is_subscribed { true }
      can_subscribe { true }
    end
  end
end
