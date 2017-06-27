FactoryGirl.define do
  factory :rate_limits, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :rate_limit_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:rate_limit_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :rate_limit_result do
      id { SecureRandom.uuid.gsub('-', '') }
      disabled { Faker::Boolean.boolean }
      description { Faker::Lorem.sentence }
      match { create(:rate_limit_match) }
      bypass { create_list(:rate_limit_bypass, 1) }
      threshold 60
      period 900
      action { create(:rate_limit_action) }
    end

    factory :rate_limit_match do
      request do
        {
          methods: %w[GET POST],
          schemes: %w[HTTP HTTPS],
          url:     "*.#{Faker::Internet.domain_name}/path*"
        }
      end
      response do
        {
          status:         [401, 403],
          origin_traffic: Faker::Boolean.boolean
        }
      end
    end

    factory :rate_limit_bypass do
      name 'url'
      value "api.#{Faker::Internet.domain_name}/*"
    end

    factory :rate_limit_action do
      mode 'simulate'
      timeout 86400
      response do
        {content_type: 'text/xml',
         body:         '<error>This request has been rate-limited.</error>'}
      end
    end

    factory :rate_limit_show do
      success true
      errors []
      messages []
      result { create(:rate_limit_result) }
    end

    factory :rate_limit_delete do
      id { SecureRandom.uuid }
    end
  end
end
