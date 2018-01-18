class CloudflareClient::Zone::Analytics < CloudflareClient::Zone::Base
  ##
  # zone analytics (free, pro, business, enterprise)

  ##
  # return dashboard data for a given zone or colo
  def zone_dashboard
    cf_get(path: "/zones/#{zone_id}/analytics/dashboard")
  end

  ##
  # creturn analytics for colos for a time window.
  # since and untill must be RFC 3339 timestamps
  # TODO: support continuous
  def colo_dashboard(since_ts: nil, until_ts: nil)
    raise 'since_ts must be a valid timestamp' if since_ts.nil? || !date_rfc3339?(since_ts)
    raise 'until_ts must be a valid timestamp' if until_ts.nil? || !date_rfc3339?(until_ts)

    cf_get(path: "/zones/#{zone_id}/analytics/dashboard")
  end

  ##
  # DNS analytics

  ##
  # return a table of analytics
  def dns_table
    cf_get(path: "/zones/#{zone_id}/dns_analytics/report")
  end

  ##
  # return analytics by time
  def dns_by_time(dimensions: [],
                  metrics: [],
                  sort: [],
                  filters: [],
                  since_ts: nil,
                  until_ts: nil,
                  limit: 100,
                  time_delta: 'hour')
    # TODO: what are valid dimensions?
    # TODO: what are valid metrics?
    unless since_ts.nil?
      raise 'since_ts must be a valid timestamp' unless date_rfc3339?(since_ts)
    end
    unless until_ts.nil?
      raise 'until_ts must be a valid timestamp' unless date_rfc3339?(until_ts)
    end

    params          = {limit: limit, time_delta: time_delta}
    params['since'] = since_ts
    params['until'] = until_ts

    cf_get(path: "/zones/#{zone_id}/dns_analytics/report/bytime", params: params)
  end
end
