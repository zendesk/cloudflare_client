FactoryGirl.define do
  factory :custom_pages, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :successful_custom_page_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:successful_custom_page_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :successful_custom_page_result do
      id { Faker::Lorem.words.join('_') }
      created_on { Time.now.utc.iso8601 }
      modified_on { Time.now.utc.iso8601 }
      url { "http://#{Faker::Internet.domain_name}" }
      state 'default'
      required_tokens %w[::CAPTCHA_BOX::]
      preview_target 'preview:target'
      description { Faker::Boolean.boolean }
    end

    factory :successful_custom_page_show do
      success true
      errors []
      messages []
      result { create(:successful_custom_page_result) }
    end
  end
end
