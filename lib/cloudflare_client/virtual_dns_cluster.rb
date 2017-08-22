class CloudflareClient::VirtualDnsCluster < CloudflareClient
  require_relative '../cloudflare_client/virtual_dns_cluster/analytic.rb'

  VALID_SCOPES = %i[user organization].freeze

  attr_reader :uri_prefix

  ##
  # virtual DNS
  # using scope to determine if this is for users or for orgs
  def initialize(args)
    scope  = args.delete(:scope)&.to_sym
    org_id = args.delete(:org_id)

    valid_value_check(:scope, scope, VALID_SCOPES)

    if scope == :user
      @uri_prefix = '/user'
    else
      id_check(:org_id, org_id)

      @uri_prefix = "/organizations/#{org_id}"
    end

    super
  end

  ##
  # list virutal dns clsuters for a user or an org
  def list
    cf_get(path: "#{uri_prefix}/virtual_dns")
  end

  ##
  # create a virtual dns cluster
  def create(name:,
             origin_ips:,
             minimum_cache_ttl: nil,
             maximum_cache_ttl: nil,
             deprecate_any_request: nil,
             ratelimit: nil)
    id_check(:name, name)
    max_length_check(:name, name, 160)
    non_empty_array_check(:origin_ips, origin_ips)

    data = {name: name, origin_ips: origin_ips}

    unless minimum_cache_ttl.nil?
      range_check(:minimum_cache_ttl, minimum_cache_ttl, 30, 36000)
      data[:minimum_cache_ttl] = minimum_cache_ttl
    end

    unless maximum_cache_ttl.nil?
      range_check(:maximum_cache_ttl, maximum_cache_ttl, 30, 36000)
      data[:maximum_cache_ttl] = maximum_cache_ttl
    end

    unless deprecate_any_request.nil?
      valid_value_check(:deprecate_any_request, deprecate_any_request, [true, false])
      data[:deprecate_any_request] = deprecate_any_request
    end

    unless ratelimit.nil?
      range_check(:ratelimit, ratelimit, 0, 100000000)
      data[:ratelimit] = ratelimit
    end

    cf_post(path: "#{uri_prefix}/virtual_dns", data: data)
  end

  ##
  # details of a cluster
  def show(id:)
    id_check(:id, id)

    cf_get(path: "#{uri_prefix}/virtual_dns/#{id}")
  end

  ##
  # delete a dns cluster (user)
  def delete(id:)
    id_check(:id, id)

    cf_delete(path: "#{uri_prefix}/virtual_dns/#{id}")
  end

  ##
  # updates a dns cluster (user)
  def update(id:,
             name: nil,
             origin_ips: nil,
             minimum_cache_ttl: nil,
             maximum_cache_ttl: nil,
             deprecate_any_request: nil,
             ratelimit: nil)
    id_check(:id, id)

    data = {}

    unless name.nil?
      id_check(:name, name)
      max_length_check(:name, name, 160)
      data[:name] = name
    end

    unless origin_ips.nil?
      non_empty_array_check(:origin_ips, origin_ips)
      data[:origin_ips] = origin_ips
    end

    unless minimum_cache_ttl.nil?
      range_check(:minimum_cache_ttl, minimum_cache_ttl, 30, 36000)
      data[:minimum_cache_ttl] = minimum_cache_ttl
    end

    unless maximum_cache_ttl.nil?
      range_check(:maximum_cache_ttl, maximum_cache_ttl, 30, 36000)
      data[:maximum_cache_ttl] = maximum_cache_ttl
    end

    unless deprecate_any_request.nil?
      valid_value_check(:deprecate_any_request, deprecate_any_request, [true, false])
      data[:deprecate_any_request] = deprecate_any_request
    end

    unless ratelimit.nil?
      range_check(:ratelimit, ratelimit, 0, 100000000)
      data[:ratelimit] = ratelimit
    end

    cf_patch(path: "#{uri_prefix}/virtual_dns/#{id}", data: data)
  end
end
