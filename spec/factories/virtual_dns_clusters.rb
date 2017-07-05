FactoryGirl.define do
  factory :virtual_dns_clusters, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :virtual_dns_cluster_list do
      transient { result_count { rand(1..3) } }
      success true
      errors []
      messages []
      result { create_list(:virtual_dns_cluster_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :virtual_dns_cluster_show do
      success true
      errors []
      messages []
      result { create(:virtual_dns_cluster_result) }
    end

    factory :virtual_dns_cluster_delete do
      success true
      errors []
      messages []
      result { {id: SecureRandom.uuid.gsub('-', '')} }
    end

    factory :virtual_dns_cluster_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Lorem.words(5).join(' ') }
      origin_ips { mixed_ip_addresses }
      virtual_dns_ips { mixed_ip_addresses }
      minimum_cache_ttl 60
      maximum_cache_ttl 900
      deprecate_any_requests { Faker::Boolean.boolean }
      ratelimit 600
      modified_on { Time.now.utc.advance(years: -2).iso8601(5) }
    end
  end
end
