FactoryBot.define do
  factory :organization_railguns, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :organization_railgun_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:organization_railgun_result) }
    end

    factory :organization_railgun_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:organization_railgun_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :organization_railgun_delete do
      success { true }
      errors { [] }
      messages { [] }
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end

    factory :organization_railgun_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Lorem.words.join(' ') }
      status { 'active' }
      enabled { Faker::Boolean.boolean }
      zones_connected { Faker::Number.number(digits: 1).to_i }
      build { "b#{Faker::Number.number(digits: 4)}" }
      version { '2.1' }
      revision { '123' }
      activation_key { SecureRandom.uuid.gsub('-', '') }
      activated_on { Time.now.utc.advance(years: -2).iso8601 }
      created_on { Time.now.utc.advance(years: -2).iso8601 }
      modified_on { Time.now.utc.advance(years: -2).iso8601 }
    end

    factory :organization_railgun_zone_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:organization_railgun_zone_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :organization_railgun_zone_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Internet.domain_name }
      development_mode { 7200 }
      original_name_servers { rand(2..4).times.map { Faker::Internet.domain_name } }
      original_registrar { Faker::Company.name }
      original_dnshost { Faker::Company.name }
      created_on { Time.now.utc.advance(years: -2).iso8601(5) }
      modified_on { Time.now.utc.advance(years: -2).iso8601(5) }
    end
  end
end
