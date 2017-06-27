FactoryGirl.define do
  factory :organizations, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :organization_show do
      success true
      errors []
      messages []
      result { create(:organization_result) }
    end

    factory :organization_result do
      transient do
        member_count { rand(1..3) }
        invite_count { rand(1..3) }
        role_count { rand(1..3) }
      end

      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Company.name }
      members { create_list(:organization_member_result, member_count) }
      invites { create_list(:organization_invite_result, invite_count) }
      roles { create_list(:organization_role_result, role_count) }
    end
  end
end
