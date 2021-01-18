FactoryBot.define do
  factory :railguns, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :successful_railgun_create do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:successful_railgun_result) }
    end

    factory :successful_railgun_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Lorem.words.join(' ') }
      status { 'active' }
      enabled { Faker::Boolean.boolean }
      zones_connected { rand(1..3) }
      build { 'b1234' }
      version { '2.1' }
      revision { '123' }
      activation_key { SecureRandom.uuid.gsub('-', '') }
      activated_on { Time.now.utc.iso8601 }
      created_on { Time.now.utc.iso8601 }
      modified_on { Time.now.utc.iso8601 }
    end

    factory :successful_railgun_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:successful_railgun_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :successful_railgun_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:successful_railgun_result) }
    end

    factory :successful_railgun_zones do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:successful_railgun_zones_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :successful_railgun_zones_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Internet.domain_name }
      development_mode { 7200 }
      original_name_servers { rand(2..4).times.map { Faker::Internet.domain_name } }
      original_registrar { Faker::Company.name }
      original_dnshost { Faker::Company.name }
      created_on { Time.now.utc.iso8601(5) }
      modified_on { Time.now.utc.iso8601(5) }
    end

    factory :successful_railgun_delete do
      success { true }
      errors { [] }
      messages { [] }
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end
  end
end
