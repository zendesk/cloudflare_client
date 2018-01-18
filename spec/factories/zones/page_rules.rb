FactoryGirl.define do
  factory :page_rules, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :page_rule_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:page_rule_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :page_rule_result do
      id { SecureRandom.uuid.gsub('-', '') }
      targets { create_list(:page_rule_target, 1) }
      actions { create_list(:page_rule_action, 1) }
      priority 1
      status 'active'
      modified_on { Time.now.utc.advance(years: -2).iso8601(5) }
      created_on { Time.now.utc.advance(years: -2).iso8601(5) }
    end

    factory :page_rule_target do
      target 'url'
      constraint do
        {
          operator: 'matches',
          value:    '*example.com/images/*'
        }
      end
    end

    factory :page_rule_action do
      id 'always_online'
      value 'on'
    end

    factory :page_rule_show do
      success true
      errors []
      messages []
      result { create(:page_rule_result) }
    end

    factory :page_rule_delete do
      id { SecureRandom.uuid }
    end
  end
end
