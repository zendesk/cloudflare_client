FactoryBot.define do
  factory :waf_packages_rule_groups, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :waf_packages_rule_group_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:waf_packages_rule_group_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :waf_packages_rule_group_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Lorem.words.join(' ') }
      description { Faker::Lorem.sentence }
      rules_count { 10 }
      modified_rules_count { 2 }
      package_id { SecureRandom.uuid.gsub('-', '') }
      mode { 'on' }
      allowed_modes { %w[on off] }
    end

    factory :waf_packages_rule_group_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:waf_packages_rule_group_result) }
    end
  end
end
