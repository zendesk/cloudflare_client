FactoryBot.define do
  factory :zone_settings, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :zone_setting_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:zone_setting_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :zone_setting_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:zone_setting_result) }
    end

    factory :zone_setting_result do
      id { 'always_online' }
      value { 'on' }
      editable { Faker::Boolean.boolean }
      modified_on { Time.now.utc.iso8601(5) }
    end
  end
end
