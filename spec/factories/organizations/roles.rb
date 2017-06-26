FactoryGirl.define do
  factory :organization_roles, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :organization_role_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:organization_role_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :organization_role_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Job.title }
      description { Faker::Hacker.say_something_smart }
      permissions '#zones:read'
    end

    factory :organization_role_show do
      success true
      errors []
      messages []
      result { create(:organization_role_result) }
    end
  end
end
