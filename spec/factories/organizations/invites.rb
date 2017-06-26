FactoryGirl.define do
  factory :organization_invites, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :organization_invite_show do
      success true
      errors []
      messages []
      result { create(:organization_invite_result) }
    end

    factory :organization_invite_result do
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

    factory :organization_invite_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:organization_invite_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :organization_invite_delete do
      id { SecureRandom.uuid.gsub('-', '') }
    end
  end
end
