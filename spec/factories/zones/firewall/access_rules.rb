FactoryGirl.define do
  factory :firewall_access_rules, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :firewall_access_rule_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:firewall_access_rule_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :firewall_access_rule_result do
      id { SecureRandom.uuid.gsub('-', '') }
      notes { Faker::Lorem.sentence }
      allowed_modes %w[whitelist block challenge]
      mode { allowed_modes.sample }
      configuration { create(:firewall_access_rule_configuration) }
      scope { create(:firewall_access_rule_scope) }
      created_on { Time.now.utc.advance(years: -2).iso8601(5) }
      modified_on { Time.now.utc.advance(years: -2).iso8601(5) }
    end

    factory :firewall_access_rule_configuration do
      target 'ip'
      value { Faker::Internet.ip_v4_address }
    end

    factory :firewall_access_rule_scope do
      id { SecureRandom.uuid.gsub('-', '') }
      email { Faker::Internet.email }
      type 'user'
    end

    factory :firewall_access_rule_show do
      success true
      errors []
      messages []
      result { create(:firewall_access_rule_result) }
    end

    factory :firewall_access_rule_delete do
      success true
      errors []
      messages []
      result { {id: SecureRandom.uuid} }
    end
  end
end
