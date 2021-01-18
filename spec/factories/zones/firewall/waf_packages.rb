FactoryBot.define do
  factory :firewall_waf_packages, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :firewall_waf_package_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:firewall_waf_package_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :firewall_waf_package_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Lorem.words.join(' ') }
      description { Faker::Lorem.sentence }
      detection_mode { 'traditional' }
      zone_id { SecureRandom.uuid.gsub('-', '') }
      status { 'active' }
    end

    factory :firewall_waf_package_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:firewall_waf_package_result) }
    end
  end
end
