FactoryBot.define do
  factory :zone_logs, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :zone_log do
      brandId { Faker::Number.number(digits: 3).to_i }
      flags { Faker::Number.number(digits: 1).to_i }
      hosterId { Faker::Number.number(digits: 1).to_i }
      ownerId { Faker::Number.number(digits: 7).to_i }
      rayId { '36527575c4556dcc' }
      securityLevel { 'high' }
      timestamp { Time.now.utc.iso8601(9) }
      unstable { nil }
      zoneId { Faker::Number.number(digits: 8).to_i }
      zoneName { Faker::Internet.domain_name }
      zonePlan { 'enterprise' }
      client { create(:zone_log_client) }
      clientRequest { create(:zone_log_client_request) }
      edge { create(:zone_log_edge) }
      edgeResponse { create(:zone_log_edge_response) }
    end

    factory :zone_log_client do
      asNum { Faker::Number.number(digits: 5).to_i }
      country { 'us' }
      deviceType { 'desktop' }
      ip { Faker::Internet.ip_v4_address }
      ipClass { 'noRecord' }
      srcPort { Faker::Number.number(digits: 4).to_i }
      sslCipher { 'NONE' }
      sslFlags { 0 }
      sslProtocol { 'none' }
    end

    factory :zone_log_client_request do
      accept { '*/*' }
      body { nil }
      bodyBytes { 0 }
      bytes { Faker::Number.number(digits: 2).to_i }
      cookies { nil }
      dnt { 'unset' }
      flags { 0 }
      headers { [] }
      httpHost { Faker::Internet.domain_name }
      httpMethod { 'GET' }
      httpProtocol { 'HTTP/1.1' }
      referer { '' }
      sslConnectionId { '' }
      uri { '/' }
      userAgent { 'curl/7.51.0' }
      signature { '' }
    end

    factory :zone_log_edge do
      bbResult { '0' }
      cacheResponseTime { 0 }
      colo { 4 }
      enabledFlags { 0 }
      endTimestamp { Time.now.utc.iso8601(9) }
      flServerIp { Faker::Internet.ip_v4_address }
      flServerName { '4f247' }
      flServerPort { 80 }
      pathingOp { 'ban' }
      pathingSrc { 'user' }
      pathingStatus { 'rateLimit' }
      startTimestamp { Time.now.utc.iso8601(9) }
      usedFlags { 0 }
      rateLimit { create(:zone_log_edge_rate_limit) }
      dnsResponse { create(:zone_log_edge_dns_response) }
    end

    factory :zone_log_edge_rate_limit do
      transient { processed_rule_count { rand(1..3) } }
      ruleId { Faker::Number.number(digits: 5).to_i }
      mitigationId { 'AFq1zr89mfJtegf89OMQ0Q==' }
      sourceId { Faker::Internet.ip_v4_address }
      processedRules { create_list(:zone_log_edge_rate_limit_processed_rule, processed_rule_count) }
    end

    factory :zone_log_edge_rate_limit_processed_rule do
      ruleId { Faker::Number.number(digits: 5).to_i }
      ruleSrc { 'user' }
      status { 'ban' }
    end

    factory :zone_log_edge_dns_response do
      rcode { 0 }
      error { 'ok' }
      cached { Faker::Boolean.boolean }
      duration { 0 }
      errorMsg { '' }
      overrideError { Faker::Boolean.boolean }
    end

    factory :zone_log_edge_response do
      bodyBytes { Faker::Number.number(digits: 4).to_i }
      bytes { Faker::Number.number(digits: 4).to_i }
      compressionRatio { 0 }
      contentType { 'text/html; charset=UTF-8' }
      headers { nil }
      setCookies { nil }
      status { 429 }
    end
  end
end
