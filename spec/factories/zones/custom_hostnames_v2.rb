FactoryBot.define do
  factory :custom_hostnames_v2, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :custom_hostname_v2_list do
      transient { result_count { rand(1..3) } }
      success { true }
      errors { [] }
      messages { [] }
      result { create_list(:custom_hostname_v2_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :custom_hostname_v2_result do
      id { SecureRandom.uuid }
      hostname { Faker::Internet.domain_name }
      ssl do
        {
          status: 'pending_validation',
          method: 'http',
          type: 'dv',
          cname_target: Faker::Internet.domain_name,
          cname: "#{SecureRandom.uuid.gsub('-', '')}.#{Faker::Internet.domain_name}"
        }
      end
    end

    factory :custom_hostname_v2_result_with_metadata do
      id { SecureRandom.uuid }
      hostname { Faker::Internet.domain_name }
      custom_metadata { { foo: 'bar' } }
      ssl do
        {
          status: 'pending_validation',
          method: 'http',
          type: 'dv',
          cname_target: Faker::Internet.domain_name,
          cname: "#{SecureRandom.uuid.gsub('-', '')}.#{Faker::Internet.domain_name}"
        }
      end
    end

    factory :custom_hostname_v2_show do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:custom_hostname_result) }
      ownership_verification_http do 
        { 
          http_url: Faker::Internet.domain_name,
          http_body: SecureRandom.uuid
        }
      end
    end

    factory :custom_hostname_v2_show_with_metadata do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:custom_hostname_result_with_metadata) }
      ownership_verification_http do 
        { 
          http_url: Faker::Internet.domain_name,
          http_body: SecureRandom.uuid
        }
      end
    end


    factory :custom_hostname_v2_update do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:custom_hostname_result) }
      status { 'pending' }
      ownership_verification_http do 
        { 
          http_url: Faker::Internet.domain_name,
          http_body: SecureRandom.uuid
        }
      end
    end

    factory :custom_hostname_v2_update_with_metadata do
      success { true }
      errors { [] }
      messages { [] }
      result { create(:custom_hostname_result_with_metadata) }
      ownership_verification_http do 
        { 
          http_url: Faker::Internet.domain_name,
          http_body: SecureRandom.uuid
        }
      end
    end

    factory :custom_hostname_v2_delete do
      id { SecureRandom.uuid }
    end
  end
end
