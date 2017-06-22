FactoryGirl.define do
  factory :custom_hostnames, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :custom_hostname_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:custom_hostname_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :custom_hostname_result do
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

    factory :custom_hostname_show do
      success true
      errors []
      messages []
      result { create(:custom_hostname_result) }
    end

    factory :custom_hostname_delete do
      id { SecureRandom.uuid }
    end
  end
end
