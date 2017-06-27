FactoryGirl.define do
  factory :waf_packages_rules, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :waf_packages_rule_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:waf_packages_rule_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :waf_packages_rule_result do
      id { SecureRandom.uuid.gsub('-', '') }
      description { Faker::Lorem.sentence }
      priority 5
      group { create(:waf_packages_rule_group) }
      package_id { SecureRandom.uuid.gsub('-', '') }
      allowed_modes %w[on off]
      mode 'on'
    end

    factory :waf_packages_rule_group do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Lorem.words.join(' ') }
    end

    factory :waf_packages_rule_show do
      success true
      errors []
      messages []
      result { create(:waf_packages_rule_result) }
    end
  end
end
