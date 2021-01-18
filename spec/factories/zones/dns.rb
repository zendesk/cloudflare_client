FactoryBot.define do
  factory :dns, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :successful_dns_query do
      transient { result_count { rand(1..5) } }
      result { create_list(:successful_dns_query_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    50,
          total_pages: 1,
          count:       result_count,
          total_count: result_count
        }
      end
      success { true }
      errors { [] }
      messages { [] }
    end

    factory :successful_dns_query_result do
      id { SecureRandom.uuid.gsub('-', '') }
      type { CloudflareClient::Zone::DNS::VALID_TYPES.sample }
      name { Faker::Internet.domain_name }
      content { Faker::Internet.ip_v4_address }
      proxiable { Faker::Boolean.boolean }
      proxied { Faker::Boolean.boolean }
      ttl { 1 }
      locked { Faker::Boolean.boolean }
      zone_id { SecureRandom.uuid.gsub('-', '') }
      zone_name { Faker::Internet.domain_name }
      modified_on { Time.now.utc.iso8601(5) }
      created_on { Time.now.utc.iso8601(5) }
      meta { {auto_added: false} }
    end

    factory :successful_dns_create do
      result { create(:successful_dns_query_result) }
      success { true }
      errors { [] }
      messages { [] }
      proxied { true }
    end

    factory :successful_dns_update do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:successful_dns_update_result) }
    end

    factory :successful_dns_update_result do
      id { SecureRandom.uuid.gsub('-', '') }
      type { CloudflareClient::Zone::DNS::VALID_TYPES.sample }
      name { Faker::Internet.domain_name }
      content { Faker::Internet.ip_v4_address }
      proxiable { Faker::Boolean.boolean }
      proxied { Faker::Boolean.boolean }
      ttl { 1 }
      locked { Faker::Boolean.boolean }
      zone_id { SecureRandom.uuid.gsub('-', '') }
      zone_name { Faker::Internet.domain_name }
      created_on { Time.now.utc.iso8601(5) }
      modified_on { Time.now.utc.iso8601(5) }
      data { {} }
    end

    factory :successful_dns_delete do
      success { true }
      errors { [] }
      messages { [] }
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end
  end
end
