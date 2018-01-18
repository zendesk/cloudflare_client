FactoryGirl.define do
  factory :ssl, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :ssl_analyze do
      success true
      errors []
      messages []
      result { create(:ssl_analyze_result) }
    end

    factory :ssl_analyze_result do
      hosts { rand(1..4).times.map { Faker::Internet.domain_name } }
      signature_algorithm 'SHA256WithRSA'
      expires_on { Time.now.utc.iso8601 }
    end

    factory :ssl_verification do
      transient { result_count { rand(1..3) } }
      result { create_list(:ssl_verification_result, result_count) }
    end

    factory :ssl_verification_result do
      certificate_status 'active'
      verification_type 'cname'
      verification_status { Faker::Boolean.boolean }
      verification_info { create(:ssl_verification_info) }
      brand_check { Faker::Boolean.boolean }
    end

    factory :ssl_verification_info do
      record_name { "#{SecureRandom.uuid.gsub('-', '')}.#{Faker::Internet.domain_name}" }
      record_target { "#{SecureRandom.uuid.gsub('-', '')}.#{Faker::Internet.domain_name}" }
    end
  end
end
