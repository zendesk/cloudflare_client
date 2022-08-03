class CloudflareClient::VirtualDnsCluster::Analytic < CloudflareClient::VirtualDnsCluster
  attr_reader :virtual_dns_id

  ##
  # virtual DNS Analytics (users and orgs)
  #
  def initialize(args)
    @virtual_dns_id = args.delete(:virtual_dns_id)
    id_check(:virtual_dns_id, virtual_dns_id)
    super(**args)
  end

  def report(dimensions:, metrics:, since_ts:, until_ts:, filters: nil, sort: nil, limit: nil)
    non_empty_array_check(:dimensions, dimensions)
    non_empty_array_check(:metrics, metrics)
    iso8601_check(:since_ts, since_ts)
    iso8601_check(:until_ts, until_ts)

    params = {dimensions: dimensions, metrics: metrics, since: since_ts, until: until_ts}

    unless sort.nil?
      non_empty_array_check(:sort, sort)
      params[:sort] = sort
    end

    unless filters.nil?
      basic_type_check(:filters, filters, String)
      params[:filters] = filters
    end

    unless limit.nil?
      basic_type_check(:limit, limit, Integer)
      params[:limit] = limit
    end

    cf_get(path: "#{uri_prefix}/virtual_dns/#{virtual_dns_id}/dns_analytics/report", params: params)
  end
end
