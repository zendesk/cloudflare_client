FactoryBot.define do
  factory :organization_members, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :organization_member_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:organization_member_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :organization_member_result do
      transient { role_count { rand(1..3) } }
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Name.name }
      email { Faker::Internet.email }
      status { 'accepted' }
      roles { create_list(:organization_role_result, role_count) }
    end

    factory :organization_member_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:organization_member_result) }
    end

    factory :organization_member_delete do
      id { SecureRandom.uuid.gsub('-', '') }
    end
  end
end
