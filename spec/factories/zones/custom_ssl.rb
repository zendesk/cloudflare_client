FactoryGirl.define do
  factory :custom_ssl, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :custom_ssl_show do
      success true
      errors []
      messages []
      result { create(:custom_ssl_result) }
    end

    factory :custom_ssl_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:custom_ssl_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :custom_ssl_delete do
      id { Faker::Lorem.words.join('_') }
    end

    factory :custom_ssl_result do
      id { Faker::Lorem.words.join('_') }
      hosts { rand(2..4).times.map { Faker::Internet.domain_name } }
      issuer { Faker::Company.name }
      signature 'SHA256WithRSA'
      state 'active'
      bundle_method { CloudflareClient::VALID_BUNDLE_METHODS.sample }
      zone_id { Faker::Lorem.words.join('_') }
      uploaded_on { Time.now.utc.advance(years: -2).iso8601 }
      modified_on { Time.now.utc.advance(years: -2).iso8601 }
      expires_on { Time.now.utc.iso8601 }
      priority 1
    end
  end
end
