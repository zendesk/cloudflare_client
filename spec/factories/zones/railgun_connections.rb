FactoryGirl.define do
  factory :railgun_connections, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :successful_railgun_connections_list do
      transient { result_count { rand(1..5) } }
      success true
      errors []
      messages []
      result { create_list(:successful_railgun_connections_result, result_count) }
      result_info do
        {
          page:        1,
          per_page:    20,
          count:       result_count,
          total_count: result_count
        }
      end
    end

    factory :successful_railgun_connections_result do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Lorem.words.join(' ') }
      enabled { Faker::Boolean.boolean }
      connected { Faker::Boolean.boolean }
    end

    factory :successful_railgun_connections_show do
      success true
      errors []
      messages []
      result { create(:successful_railgun_connections_result) }
    end

    factory :successful_railgun_connections_test do
      success true
      errors []
      messages []
      result do
        {
          method:           'GET',
          host_name:        Faker::Internet.domain_name,
          http_status:      200,
          railgun:          'on',
          url:              'https://www.cloudflare.com',
          response_status:  '200 OK',
          protocol:         'HTTP/1.1',
          elapsed_time:     "#{rand.round(6)}s",
          body_size:        "#{Faker::Number.number(5)} bytes",
          body_hash:        SecureRandom.hex(20),
          missing_headers:  'No Content-Length or Transfer-Encoding',
          connection_close: Faker::Boolean.boolean,
          cloudflare:       'on',
          "cf-ray"          => "#{SecureRandom.hex(8)}-LAX",
          "cf-wan-error"    => nil,
          "cf-cache-status" => nil
        }
      end
    end

    factory :successful_railgun_connections_connect do
      success true
      errors []
      messages []
      result { create(:successful_railgun_connections_result, connected: true) }
    end

    factory :successful_railgun_connections_disconnect do
      success true
      errors []
      messages []
      result { create(:successful_railgun_connections_result, connected: false) }
    end
  end
end
