FactoryBot.define do
  factory :organization_access_rules, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :organization_access_rule_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:organization_access_rule_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :organization_access_rule_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:organization_access_rule_result) }
    end

    factory :organization_access_rule_delete do
      success { true }
      errors { [] }
      messages { [] }
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end

    factory :organization_access_rule_result do
      id { SecureRandom.uuid.gsub('-', '') }
      notes { Faker::Lorem.sentence }
      allowed_modes { CloudflareClient::Organization::AccessRule::VALID_MODES }
      mode { CloudflareClient::Organization::AccessRule::VALID_MODES.sample }
      configuration { create(:organization_access_rule_configuration) }
      scope { create(:organization_access_rule_scope) }
      created_on { Time.now.utc.advance(years: -2).iso8601(5) }
      modified_on { Time.now.utc.advance(years: -2).iso8601(5) }
    end

    factory :organization_access_rule_configuration do
      target { 'ip' }
      value { Faker::Internet.ip_v4_address }
    end

    factory :organization_access_rule_scope do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Company.name }
      type { "organization" }
    end
  end
end
