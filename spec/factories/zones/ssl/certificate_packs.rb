FactoryGirl.define do
  factory :certificate_packs, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :certificate_pack_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:certificate_pack_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :certificate_pack_result do
      transient { certificate_count { rand(1..3) } }
      id { SecureRandom.uuid }
      type 'custom'
      hosts { rand(1..3).times.map { Faker::Internet.domain_name } }
      certificates { create_list(:certificate, certificate_count) }
      primary_certificate { SecureRandom.uuid.gsub('-', '') }
    end

    factory :certificate do
      id { SecureRandom.uuid.gsub('-', '') }
      hosts { rand(1..3).times.map { Faker::Internet.domain_name } }
      issuer Faker::Company.name
      signature_algorithm 'SHA256WithRSA'
      status 'active'
      bundle_method { CloudflareClient::VALID_BUNDLE_METHODS.sample }
      zone_id { SecureRandom.uuid.gsub('-', '') }
      uploaded_on { Time.now.utc.advance(years: -1).iso8601 }
      modified_on { Time.now.utc.advance(years: -1).iso8601 }
      expires_on { Time.now.utc.iso8601 }
      priority 1
    end

    factory :certificate_pack_show do
      success true
      errors []
      messages []
      result { create(:certificate_pack_result) }
    end
  end
end
