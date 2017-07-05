FactoryGirl.define do
  factory :virtual_dns_cluster_analytics, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :virtual_dns_cluster_analytic_report do
      success true
      errors []
      messages []
      result { create(:virtual_dns_cluster_analytic_result) }
      query { create(:virtual_dns_cluster_analytic_query) }
    end

    factory :virtual_dns_cluster_analytic_result do
      data { create(:virtual_dns_cluster_analytic_data) }
      totals { {queryCount: 1000, responseTimeAvg: 1} }
      min { {queryCount: 1000, responseTimeAvg: 1} }
      max { {queryCount: 1000, responseTimeAvg: 1} }
    end

    factory :virtual_dns_cluster_analytic_data do
      dimensions { [name: 'NODATA'] }
      metrics { [1.5, 2] }
    end

    factory :virtual_dns_cluster_analytic_query do
      dimensions %w[responseCode queryName]
      metrics %w[queryCount responseTimeAvg]
      sort %w[+responseCode -queryName]
      filters 'responseCode==NOERROR'
      since { Time.now.utc.advance(hours: -1).iso8601 }
      add_attribute(:until) { Time.now.utc.iso8601 }
      limit 100
    end
  end
end
