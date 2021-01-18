FactoryBot.define do
  factory :keyless_ssl, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :keyless_ssl_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:keyless_ssl_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :keyless_ssl_result do
      transient { hostname { Faker::Internet.domain_name } }
      id { SecureRandom.uuid.gsub('-', '') }
      name { "#{hostname} Keyless SSL" }
      host { hostname }
      port { 24008 }
      status { 'active' }
      enabled { Faker::Boolean.boolean }
      permissions { %w[#ssl:read #ssl:edit] }
      created_on { Time.now.utc.advance(years: -2).iso8601 }
      modified_on { Time.now.utc.advance(years: -2).iso8601 }
    end

    factory :keyless_ssl_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:keyless_ssl_result) }
    end

    factory :keyless_ssl_delete do
      id { SecureRandom.uuid }
    end
  end
end
