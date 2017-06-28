##
# General class for the client
class CloudflareClient
  require 'json'
  require 'faraday'
  require 'date'
  require 'byebug'
  Dir[File.expand_path('../zendesk_cloudflare/*.rb', __FILE__)].each {|f| require f}

  API_BASE = 'https://api.cloudflare.com/client/v4'.freeze
  VALID_BUNDLE_METHODS = %w[ubiquitous optimal force].freeze
  VALID_DIRECTIONS = %w[asc desc].freeze
  VALID_MATCHES  = %w[any all].freeze

  POSSIBLE_API_SETTINGS = %w[
    advanced_ddos
    always_online
    automatic_https_rewrites
    browser_cache_ttl
    browser_check
    cache_level
    challenge_ttl
    development_mode
    email_obfuscation
    hotlink_protection
    ip_geolocation
    ipv6
    minify
    mobile_redirect
    mirage
    origin_error_page_pass_thru
    opportunistic_encryption
    polish
    webp
    prefetch_preload
    response_buffering
    rocket_loader
    security_header
    security_level
    server_side_exclude
    sort_query_string_for_cache
    ssl
    tls_1_2_only
    tls_1_3
    tls_client_auth
    true_client_ip_header
    waf
    http2
    pseudo_ipv4
    websockets
  ].freeze

  def initialize(auth_key: nil, email: nil)
    raise('Missing auth_key') if auth_key.nil?
    raise('missing email') if email.nil?
    @cf_client ||= build_client(auth_key: auth_key, email: email)
  end

  ##
  # org railgun

  ##
  # list railguns
  def create_org_railguns(org_id:, name:)
    id_check('org_id', org_id)
    id_check('name', name)
    data = {name: name}
    cf_post(path: "/organizations/#{org_id}/railguns", data: data)
  end

  ##
  # list railguns
  def org_railguns(org_id:, page: 1, per_page: 50, direction: 'desc')
    id_check('org_id', org_id)
    params = {page: page, per_page: per_page, direction: direction}
    raise("direction must be either asc or desc") unless %w[asc desc].include?(direction)
    cf_get(path: "/organizations/#{org_id}/railguns", params: params)
  end

  ##
  # list railgun details
  def org_railgun(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_get(path: "/organizations/#{org_id}/railguns/#{id}")
  end

  ##
  # get zones connected to a given railgun
  def org_railgun_connected_zones(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_get(path: "/organizations/#{org_id}/railguns/#{id}/zones")
  end

  ##
  # enable or disable a railgun
  def enable_org_railgun(org_id:, id:, enabled:)
    id_check('org_id', org_id)
    id_check('id', id)
    id_check('enabled', enabled)
    raise ('enabled must be true or false') unless (enabled == true || enabled == false)
    cf_patch(path: "/organizations/#{org_id}/railguns/#{id}", data: {enabled: enabled})
  end

  ##
  # delete an org railgun
  def delete_org_railgun(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_delete(path: "/organizations/#{org_id}/railguns/#{id}")
  end

  ##
  # cloudflare CA

  ##
  # list certificates
  def certificates(zone_id: nil)
    cf_get(path: '/certificates', params: {zone_id: zone_id})
  end

  ##
  # create a certificate
  def create_certificate(hostnames:, requested_validity: 5475, request_type: 'origin-rsa', csr: nil)
    raise('hostnames must be an array') unless hostnames.is_a?(Array)
    raise('hostnames cannot be empty') if hostnames.empty?
    possible_validity = [7, 30, 90, 365, 730, 1095, 5475]
    unless possible_validity.include?(requested_validity)
      raise("requested_validity must be one of #{possible_validity.flatten}")
    end
    possible_types = %w[origin-rsa origin-ecc keyless-certificate]
    unless possible_types.include?(request_type)
      raise("request type must be one of #{possible_types.flatten}")
    end
    data = {hostnames: hostnames, requested_validity: 5475, request_type: 'origin-rsa'}
    data[:csr] = csr unless csr.nil?
    cf_post(path: '/certificates', data: data)
  end

  ##
  # details of a certificate
  def certificate(id:)
    id_check('id', id)
    cf_get(path: "/certificates/#{id}")
  end

  ##
  # revoke a cert
  def revoke_certificate(id:)
    #FIXME: what is the
    id_check('id', id)
    cf_delete(path: "/certificates/#{id}")
  end


  ##
  # virtual DNS
  # using scope to determine if this is for users or for orgs

  ##
  # list virutal dns clsuters for a user or an org
  def virtual_dns_clusters(scope:, org_id: nil)
    virtual_dns_scope(scope)
    if scope == 'user'
      cf_get(path: '/user/virtual_dns')
    elsif scope == 'organization'
      id_check('org_id', org_id)
      cf_get(path: "/organizations/#{org_id}/virtual_dns")
    end
  end

  ##
  # create a virtual dns cluster
  def create_virtual_dns_cluster(name:, origin_ips:, scope:, org_id: nil, minimum_cache_ttl: 60, maximum_cache_ttl: 900, deprecate_any_request: true, ratelimit: 0)
    id_check("name", name)
    unless (origin_ips.is_a?(Array) && !origin_ips.empty?)
      raise('origin_ips must be an array of ips (v4 or v6)')
    end
    unless (deprecate_any_request == true || deprecate_any_request == false)
      raise ("deprecate_any_request must be boolean")
    end
    virtual_dns_scope(scope)
    data = {
      name: name,
      origin_ips: origin_ips,
      minimum_cache_ttl: minimum_cache_ttl,
      maximum_cache_ttl: maximum_cache_ttl,
      deprecate_any_request: deprecate_any_request,
      ratelimit: ratelimit,
    }
    if scope == 'user'
      cf_post(path: '/user/virtual_dns', data: data)
    elsif scope == 'organization'
      id_check('org_id', org_id)
      cf_post(path: "/organizations/#{org_id}/virtual_dns", data: data)
    end
  end

  ##
  # details of a cluster
  def virtual_dns_cluster(id:, scope:, org_id: nil)
    id_check('id', id)
    virtual_dns_scope(scope)
    if scope == 'user'
      cf_get(path: "/user/virtual_dns/#{id}")
    elsif scope == 'organization'
      id_check('org_id', org_id)
      cf_get(path: "/organizations/#{org_id}/virtual_dns/#{id}")
    end
  end

  ##
  # delete a dns cluster (user)
  def delete_virtual_dns_cluster(id:, scope:, org_id: nil)
    id_check('id', id)
    virtual_dns_scope(scope)
    if scope == 'user'
      cf_delete(path: "/user/virtual_dns/#{id}")
    elsif scope == 'organization'
      id_check('org_id', org_id)
      cf_delete(path: "/organizations/#{org_id}/virtual_dns/#{id}")
    end
  end

  ##
  # updates a dns cluster (user)
  def update_virtual_dns_cluster(id:, scope:, name: nil, origin_ips: nil, minimum_cache_ttl: nil, maximum_cache_ttl: nil, deprecate_any_request: nil, ratelimit: nil, org_id: nil)
    id_check('id', id)
    unless origin_ips.nil?
      unless (origin_ips.is_a?(Array) && !origin_ips.empty?)
        raise('origin_ips must be an array of ips (v4 or v6)')
      end
    end
    unless deprecate_any_request.nil?
      unless (deprecate_any_request == true || deprecate_any_request == false)
        raise ("deprecate_any_request must be boolean")
      end
    end
    virtual_dns_scope(scope)
    data = {}
    data[:name] = name unless name.nil?
    data[:origin_ips] = origin_ips unless origin_ips.nil?
    data[:minimum_cache_ttl] = minimum_cache_ttl unless minimum_cache_ttl.nil?
    data[:maximum_cache_ttl] = maximum_cache_ttl unless maximum_cache_ttl.nil?
    data[:deprecate_any_request] = deprecate_any_request unless deprecate_any_request.nil?
    data[:ratelimit] = ratelimit unless ratelimit.nil?
    if scope == 'user'
      cf_patch(path: "/user/virtual_dns/#{id}", data: data)
    elsif scope == 'organization'
      cf_patch(path: "/organizations/#{org_id}/virtual_dns/#{id}", data: data)
    end
  end

  def virtual_dns_scope(scope)
    unless virtual_dns_scope_valid?(scope)
      raise ("scope must be user or organization")
    end
  end

  ##
  # virtual DNS Analytics (users and orgs)
  #

  def virtual_dns_analytics(id:, scope:, org_id: nil, dimensions:, metrics:, since_ts:, until_ts:, limit: 100, filters: nil, sort: nil)
    id_check('id', id)
    virtual_dns_scope(scope)
    unless dimensions.is_a?(Array) && !dimensions.empty?
      raise ("dimensions must ba an array of possible dimensions")
    end
    unless metrics.is_a?(Array) && !metrics.empty?
      raise ("metrics must ba an array of possible metrics")
    end
    raise ('since_ts must be a valid iso8601 timestamp') unless date_iso8601?(since_ts)
    raise ('until_ts must be a valid iso8601 timestamp') unless date_iso8601?(until_ts)

    params = {
      limit: limit,
      dimensions: dimensions,
      metrics: metrics,
      since: since_ts,
      until: until_ts
    }
    params[:sort] = sort unless sort.nil?
    params[:filters] = sort unless filters.nil?

    if scope == 'user'
      cf_get(path: "/user/virtual_dns/#{id}/dns_analytics/report", params: params)
    elsif scope == 'organization'
      id_check('org_id', org_id)
      cf_get(path: "/organizations/#{org_id}/virtual_dns/#{id}/dns_analytics/report", params: params)
    end
  end
  #TODO: add the time based stuff

  #TODO: cloudflare IPs
  #TODO: AML
  #TODO: load balancer monitors
  #TODO: load balancer pools
  #TODO: org load balancer monitors
  #TODO: org load balancer pools
  #TODO: load balancers
  #

  ##
  # Logs. This isn't part of the documented api, but is needed functionality

  #FIXME: make sure this covers all the logging cases

  ##
  # get logs using only timestamps
  def get_logs_by_time(zone_id:, start_time:, end_time: nil, count: nil)
    id_check('zone_id', zone_id)
    id_check('start_time', start_time)
    raise('start_time must be a valid unix timestamp') unless valid_timestamp?(start_time)
    params = {start: start_time}
    unless end_time.nil?
      raise('end_time must be a valid unix timestamp') unless valid_timestamp?(end_time)
      params[:end] = end_time
    end
    params[:count] = count unless count.nil?
    cf_get(path: "/zones/#{zone_id}/logs/requests", params: params, extra_headers: {'Accept-encoding': 'gzip'})
  end

  ##
  # get a single log entry by it's ray_id
  def get_log(zone_id:, ray_id:)
    cf_get(path: "/zones/#{zone_id}/logs/requests/#{ray_id}")
  end

  ##
  # get all logs after a given ray_id.  end_time must be a valid unix timestamp
  def get_logs_since(zone_id:, ray_id:, end_time: nil, count: nil, extra_headers: {'Accept-encoding': 'gzip'})
    params = {start_id: ray_id}
    unless end_time.nil?
      raise('end time must be a valid unix timestamp') unless valid_timestamp?(end_time)
      params[:end] = end_time
    end
    params[:count] = count unless count.nil?
    cf_get(path: "/zones/#{zone_id}/logs/requests/#{ray_id}", params: params, extra_headers: {'Accept-encoding': 'gzip'})
  end

  private

  def virtual_dns_scope_valid?(scope)
    if (scope != 'user' && scope != 'organization')
      return false
    end
    true
  end

  def valid_timestamp?(ts)
    begin
      Time.at(ts).to_datetime
    rescue TypeError
      return false
    end
    true
  end

  def bundle_method_check(bundle_method)
    unless VALID_BUNDLE_METHODS.include?(bundle_method)
      raise("valid bundle methods are #{VALID_BUNDLE_METHODS.flatten}")
    end
  end

  def date_rfc3339?(ts)
    begin
      DateTime.rfc3339(ts)
    rescue ArgumentError
      return false
    end
    true
  end

  def date_iso8601?(ts)
    begin
      DateTime.iso8601(ts)
    rescue ArgumentError
      return false
    end
    true
  end

  def id_check(name, id)
    raise "#{name} required" if id.nil?
  end

  def valid_value_check(name, value, valid_values)
    raise "#{name} must be one of #{valid_values}" unless valid_values.include?(value)
  end

  def non_empty_array_check(name, array)
    raise "#{name} must be an array of #{name}" unless array.is_a?(Array) && !array.empty?
  end

  def non_empty_hash_check(name, hash)
    raise "#{name} must be an hash of #{name}" unless hash.is_a?(Hash) && !hash.empty?
  end

  def basic_type_check(name, value, type)
    raise "#{name} must be a #{type}" unless value.is_a?(type)
  end

  def max_length_check(name, value, max_length=32)
    raise "the length of #{name} must not exceed #{max_length}" unless value.length <= max_length
  end

  def build_client(params)
    raise('Missing auth_key') if params[:auth_key].nil?
    raise('Missing auth email') if params[:email].nil?
    # we need multipart form encoding for some of these operations
    client = Faraday.new(url:  API_BASE) do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.adapter :net_http
    end
    client.headers['X-Auth-Key'] = params[:auth_key]
    client.headers['X-Auth-User-Service-Key	'] = params[:auth_key] #FIXME, is this always the same?
    client.headers['X-Auth-Email'] = params[:email]
    client.headers['Content-Type'] = 'application/json'
    client
  end

  def cf_post(path: nil, data: {})
    raise('No data to post') if data.empty?
    result = @cf_client.post do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_get(path: nil, params: {}, raw: nil, extra_headers: {})
    result = @cf_client.get do |request|
      request.headers.merge!(extra_headers) unless extra_headers.empty?
      request.url(API_BASE + path) unless path.nil?
      unless params.nil?
        request.params = params if params.values.any? { |i| !i.nil?}
      end
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    unless raw.nil?
      return result.body
    end
    # we ask for compressed logs.  uncompress if we get them
    # as the user can always ask for raw stuff
    if result.headers["content-encoding"] == 'gzip'
      return Zlib::GzipReader.new(StringIO.new(result.body.to_s)).read
    end
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_put(path: nil, data: nil)
    result = @cf_client.put do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.nil?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_patch(path: nil, data: {})
    valid_response_codes = [200, 202]
    result = @cf_client.patch do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.empty?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless valid_response_codes.include?(result.status)
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_delete(path: nil, data: {})
    result = @cf_client.delete do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.empty?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    JSON.parse(result.body, symbolize_names: true)
  end

  def valid_setting?(name = nil)
    return false if name.nil?
    return false unless POSSIBLE_API_SETTINGS.include?(name)
    true
  end
end
