FactoryGirl.define do
  factory :analytics, class: Hash do
    skip_create
    initialize_with { attributes.stringify_keys.with_indifferent_access }

    factory :successful_zone_analytics_dashboard do
      transient { timeseries_count 1 }
      success true
      errors []
      messages []
      result do
        {
          totals:     create(:analytics_totals),
          timeseries: create_list(:analytics_totals, timeseries_count)
        }
      end
      query do
        {
          since:      Time.now.utc.advance(days: -1).iso8601,
          until:      Time.now.utc.iso8601,
          time_delta: 60
        }
      end
    end

    factory :analytics_totals do
      since { Time.now.utc.advance(days: -1).iso8601 }
      add_attribute(:until) { Time.now.utc.iso8601 }
      requests do
        {
          all:          Faker::Number.number(10),
          cached:       Faker::Number.number(10),
          uncached:     Faker::Number.number(8),
          content_type: create(:analytics_content_type),
          country:      create(:analytics_countries)[:countries],
          ssl:          create(:analytics_ssl),
          http_status:  create(:analytics_http_status)
        }
      end
      bandwidth do
        {
          all:          Faker::Number.number(10),
          cached:       Faker::Number.number(10),
          uncached:     Faker::Number.number(8),
          content_type: create(:analytics_content_type),
          country:      create(:analytics_countries)[:countries],
          ssl:          create(:analytics_ssl)
        }
      end
      threats do
        {
          all:     Faker::Number.number(10),
          country: create(:analytics_countries)[:countries],
          type:    create(:analytics_threat_types)
        }
      end
      pageviews do
        {
          all:            Faker::Number.number(10),
          search_engines: create(:analytics_search_engines)
        }
      end
      uniques { {all: Faker::Number.number(5)} }
    end

    factory :analytics_content_type do
      css { Faker::Number.number(rand(5..7)) }
      html { Faker::Number.number(rand(5..7)) }
      javascript { Faker::Number.number(rand(5..7)) }
      gif { Faker::Number.number(rand(5..7)) }
      jpeg { Faker::Number.number(rand(5..7)) }
    end

    factory :analytics_countries do
      countries do
        %w[US AG GI CN AU].sample(3).reduce({}) do |hash, country_code|
          hash[country_code] = Faker::Number.number(rand(5..7))
          hash
        end
      end
    end

    factory :analytics_ssl do
      encrypted { Faker::Number.number(rand(5..7)) }
      unencrypted { Faker::Number.number(rand(5..7)) }
    end

    factory :analytics_http_status do
      add_attribute('200') { Faker::Number.number(rand(3..8)) }
      add_attribute('301') { Faker::Number.number(rand(3..8)) }
      add_attribute('400') { Faker::Number.number(rand(3..8)) }
      add_attribute('402') { Faker::Number.number(rand(3..8)) }
      add_attribute('404') { Faker::Number.number(rand(3..8)) }
    end

    factory :analytics_threat_types do
      add_attribute('user.ban.ip') { Faker::Number.number(rand(3..4)) }
      add_attribute('hot.ban.unknown') { Faker::Number.number(rand(3..4)) }
      add_attribute('macro.chl.captchaErr') { Faker::Number.number(rand(3..4)) }
      add_attribute('macro.chl.jschlErr') { Faker::Number.number(rand(3..4)) }
    end

    factory :analytics_search_engines do
      add_attribute('googlebot') { Faker::Number.number(rand(4..5)) }
      add_attribute('pingdom') { Faker::Number.number(rand(4..5)) }
      add_attribute('bingbot') { Faker::Number.number(rand(4..5)) }
      add_attribute('baidubot') { Faker::Number.number(rand(4..5)) }
    end

    factory :successful_colo_analytics_dashboard do
      transient { timeseries_count 1 }
      success true
      errors []
      messages []
      result do
        {
          colo_id:    'SFO',
          timeseries: create_list(:analytics_totals, timeseries_count)
        }
      end
      query do
        {
          since:      Time.now.utc.advance(days: -1).iso8601,
          until:      Time.now.utc.iso8601,
          time_delta: 60
        }
      end
    end

    factory :successful_dns_analytics_table do
      success true
      errors []
      messages []
      result do
        {
          data:   {
            dimensions: [name: 'NODATA'],
            metrics:    [1.5, 2]
          },
          totals: {
            queryCount:      1000,
            responseTimeAvg: 1
          },
          min:    {
            queryCount:      1000,
            responseTimeAvg: 1
          },
          max:    {
            queryCount:      1000,
            responseTimeAvg: 1
          }
        }
      end
      query do
        {
          dimensions: %w[responseCode queryName],
          metrics:    %w[queryCount responseTimeAvg],
          sort:       %w[+responseCode -queryName],
          filters:    'responseCode==NOERROR',
          since:      Time.now.utc.advance(hours: -1).iso8601,
          until:      Time.now.utc.iso8601,
          limit:      100
        }
      end
    end
  end
end
