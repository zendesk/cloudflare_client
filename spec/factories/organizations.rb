FactoryGirl.define do
  factory :organizations, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

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
      members { create_list(:organization_member, member_count) }
      invites { create_list(:organization_invite, invite_count) }
      roles { create_list(:organization_member_role, role_count) }
    end

    factory :organization_member do
      transient { role_count { rand(1..3) } }
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Name.name }
      email { Faker::Internet.email }
      status 'accepted'
      roles { create_list(:organization_member_role, role_count) }
    end

    factory :organization_member_role do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Job.title }
      description { Faker::Hacker.say_something_smart }
      permissions '#zones:read'
    end

    factory :organization_invite do
      transient { role_count { rand(1..3) } }
      id { SecureRandom.uuid.gsub('-', '') }
      invited_member_id { SecureRandom.uuid.gsub('-', '') }
      invited_member_email { Faker::Internet.email }
      organization_id { SecureRandom.uuid.gsub('-', '') }
      organization_name { Faker::Company.name }
      roles { create_list(:organization_member_role, role_count) }
      invited_by { Faker::Internet.email }
      invited_on { Time.now.utc.advance(years: -2).iso8601 }
      expires_on { Time.now.utc.advance(years: -2).iso8601 }
      status 'accepted'
    end
  end
end
