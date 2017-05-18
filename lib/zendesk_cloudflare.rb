##
# General class for the client
class CloudflareClient
  require 'json'
  require 'faraday'
  require 'date'
  require 'byebug'

  API_BASE = 'https://api.cloudflare.com/client/v4'.freeze
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
  # Zone based operations

  ##
  # list_zones will either list all zones or search for zones based on params
  # results are paginated!
  # list_zones(name: name_of_zone, status: active|pending, page: page_no)
  def list_zones(name: nil, status: nil, per_page: 50, page: 1)
    params = {}
    params[:per_page] = per_page
    params[:page]     = page
    params[:name]     = name unless name.nil?
    params[:status]   = status unless status.nil?
    cf_get(path: '/zones', params: params)
  end

  ##
  # create's a zone with a given name
  # create_zone(name: name_of_zone, jump_start: true|false (default true),
  # organization: {id: org_id, name: org_name})
  def create_zone(name: nil, jump_start: true, organization: { id: nil, name: nil })
    raise('Zone name required') if name.nil?
    raise('Organization information required') if organization[:id].nil?
    org_data = organization.merge(status: 'active', permissions: ['#zones:read'])
    data = { name: name, jump_start: jump_start, organization: org_data }
    cf_post(path: '/zones', data: data)
  end

  ##
  # request another zone activation (ssl) check
  # zone_activation_check(zone_id: id_of_your_zone)
  def zone_activation_check(zone_id: nil)
    raise('zone_id required') if zone_id.nil?
    cf_put(path: "/zones/#{zone_id}/activation_check")
  end

  ##
  # return all the details for a given zone_id
  # zone_details(zone_id: id_of_my_zone
  def zone_details(zone_id: nil)
    raise('zone_id required') if zone_id.nil?
    cf_get(path: "/zones/#{zone_id}")
  end

  ##
  # edit the properties of a zone
  # NOTE: some of these options require an enterprise account
  # edit_zone(zone_id: id_of_zone, paused: true|false,
  # vanity_name_servers: ['ns1.foo.bar', 'ns2.foo.bar'], plan: {id: plan_id})
  def edit_zone(zone_id: nil, paused: nil, vanity_name_servers: [], plan: { id: nil })
    raise('zone_id required') if zone_id.nil?
    data = {}
    data[:paused] = paused unless paused.nil?
    data[:vanity_name_servers] = vanity_name_servers unless vanity_name_servers.empty?
    data[:plan] = plan unless plan[:id].nil?
    cf_patch(path: "/zones/#{zone_id}", data: data)
  end

  ##
  # various zone caching controlls.
  # supploy an array of tags, or files, or the purge_everything bool
  def purge_zone_cache(zone_id: nil, tags: [], files: [], purge_everything: nil)
    raise('zone_id required') if zone_id.nil?
    if purge_everything.nil? && (tags.empty? && files.empty?)
      raise('specify a combination tags[], files[] or purge_everything')
    end
    data = {}
    data[:purge_everything] = purge_everything unless purge_everything.nil?
    data[:tags] = tags unless tags.empty?
    data[:files] = files unless files.empty?
    cf_delete(path: "/zones/#{zone_id}/purge_cache", data: data)
  end

  ##
  # delete a given zone
  # delete_zone(zone_id: id_of_zone
  def delete_zone(zone_id: nil)
    raise('zone_id required') if zone_id.nil?
    cf_delete(path: "/zones/#{zone_id}")
  end

  ##
  # return all settings for a given zone
  def zone_settings(zone_id: nil)
    raise('zone_id required') if zone_id.nil?
    cf_get(path: '/zones/#{zone_id}/settings')
  end

  ##
  # there are a lot of settings that can be returned.
  def zone_setting(zone_id: nil, name: nil)
    raise('zone_id required') if zone_id.nil?
    raise('setting_name not valid') if name.nil? || !valid_setting?(name)
    cf_get(path: "/zones/#{zone_id}/settings/#{name}")
  end

  ##
  # update 1 or more settings in a zone
  # settings: [{name: value: true},{name: 'value'}...]
  # https://api.cloudflare.com/#zone-settings-properties
  def update_zone_settings(zone_id: nil, settings: [])
    raise('zone_id required') if zone_id.nil?
    data = settings.map do |setting|
      raise("setting_name \"#{setting[:name]}\" not valid") unless valid_setting?(setting[:name])
      { id: setting[:name], value: setting[:value] }
    end
    data = { 'items': data }
    cf_patch(path: "/zones/#{zone_id}/settings", data: data)
  end

  ##
  # DNS methods

  ##
  # Create a dns record
  def create_dns_record(zone_id: nil, name: nil, type: nil, content: nil)
    raise("Must specificy zone_id, name, type, and content") if (zone_id.nil? || name.nil? || type.nil? || content.nil?)
    data = {name: name, type: type, content: content}
    cf_post(path: "/zones/#{zone_id}/dns_records", data: data)
  end

  ##
  # list/search for dns records in a given zone
  def dns_records(zone_id: nil, name: nil, content: nil, per_page: 50, page_no: 1, order: "type", match: "all", type: nil)
    raise("zone_id required") if zone_id.nil?
    raise("match must be either all | any") unless (match == "all" || match == "any")
    params = {per_page: per_page, page: page_no, order: order}
    params[:name]     = name unless name.nil?
    params[:content]  = content unless content.nil?
    params[:type]     = type unless type.nil?
    cf_get(path: "/zones/#{zone_id}/dns_records", params: params)
  end

  ##
  # details for a given dns_record
  def dns_record(zone_id: nil, id: nil)
    raise("zone_id required") if zone_id.nil?
    raise("dns record id required") if id.nil?
    cf_get(path: "/zones/#{zone_id}/dns_records/#{id}")
  end

  ##
  # update a dns record.
  # zone_id, id, type, and name are all required.  ttl and proxied are optional
  def update_dns_record(zone_id: nil, id: nil, type: nil, name: nil, content: nil, ttl: nil, proxied: nil)
    raise("zone_id required") if zone_id.nil?
    raise("id required") if id.nil?
    raise("must suply type, name, and content") if (type.nil? || name.nil? || content.nil?)
    data = {type: type, name: name, content: content}
    data[:ttl] = ttl unless ttl.nil?
    data[:proxied] = proxied unless proxied.nil?
    cf_put(path: "/zones/#{zone_id}/dns_records/#{id}", data: data)
  end

  ##
  # delete a dns record
  # zone_id, id, type, and name are all required.  ttl and proxied are optional
  def delete_dns_record(zone_id: nil, id: nil)
    raise("zone_id required") if zone_id.nil?
    raise("id required") if id.nil?
    cf_delete(path: "/zones/#{zone_id}/dns_records/#{id}")
  end

  ##
  # import a BIND formatted zone file
#  def import_zone_file(zone_id: nil, path_to_file: nil)
#    # FIXME: not tested
#    raise("zone_id required") if zone_id.nil?
#    raise("full path of file to import") if path_to_file.nil?
#    # TODO: ensure that this is a bind file?
#    raise("import file_name does not exist") if File.exists?(path_to_file)
#    data = { file: Faraday::UploadIO.new(path_to_file, 'multipart/form-data') }
#    cf_post(path: "/v4/zones/#{zone_id}/dns_records/import", data: data)
#  end


  ##
  # Railgun connections

  ##
  # available railguns
  def available_railguns(zone_id: nil)
    raise ("zone_id required") if zone_id.nil?
    cf_get(path: "/zones/#{zone_id}/railguns")
  end

  ##
  # details of a single railgun
  def railgun_details(zone_id: nil, id: nil)
    raise ("zone_id required") if zone_id.nil?
    raise ("railgun id required") if id.nil?
    cf_get(path: "/zones/#{zone_id}/railguns/#{id}")
  end

  ##
  # test a railgun connection
  def test_railgun_connection(zone_id: nil, id: nil)
    raise ("zone_id required") if zone_id.nil?
    raise ("railgun id required") if id.nil?
    cf_get(path: "/zones/#{zone_id}/railguns/#{id}/diagnose")
  end

  ##
  # connect or disconnect a railgun
  def connect_railgun(zone_id: nil, id: nil, connected: nil)
    zone_id_check(zone_id)
    raise ("railgun id required") if id.nil?
    raise ("connected must be true or false") if connected.nil?
    data = {connected: connected}
    cf_patch(path: "/zones/#{zone_id}/railguns/#{id}", data: data)
  end

  ##
  # zone analytics (free, pro, business, enterprise)

  ##
  # return dashboard data for a given zone or colo
  def zone_analytics_dashboard(zone_id: nil)
    zone_id_check(zone_id)
    cf_get(path: "/zones/#{zone_id}/analytics/dashboard")
  end

  ##
  # creturn analytics for colos for a time window.
  # since and untill must be RFC 3339 timestamps
  def colo_analytics(zone_id: nil, since_ts: nil, until_ts: nil)
    zone_id_check(zone_id)
    raise("since_ts must be a valid timestamp") if since_ts.nil? || !date_rfc3339?(since_ts)
    raise("until_ts must be a valid timestamp") if until_ts.nil? || !date_rfc3339?(until_ts)
    cf_get(path: "/zones/#{zone_id}/analytics/dashboard")
  end

  #TODO: dns analyitics

  #TODO: railgun

  #TODO: custom_pages_for_a_zone

  #TODO: custom ssl for a zon

  #TODO: custom_hostnames

  #TODO: keyless_ssl

  #TODO: page_rules_for_a_zone
  #TODO: rate_limits_for_a_zone
  #TODO: firewall_access_rules_for_a_zone
  #TODO: waf_rule_packages
  #TODO: waf_rule_groups
  #TODO: waf_rules
  #TODO: analyze_certificate
  #TODO: certificate_packs
  #TODO: ssl_verification
  #TODO: zone_subscription
  #TODO: organizations
  #TODO: org members
  #TODO: org invites
  #TODO: org roles
  #TODO: org level firewall rules
  #TODO: org railgun
  #TODO: cloudflare CA
  #TODO: virtual DNS users
  #TODO: virtual DNS org
  #TODO: virtual DNS Analytics users
  #TODO: virtual DNS Analytics org
  #TODO: cloudflare IPs
  #TODO: AML
  #TODO: load balancer monitors
  #TODO: load balancer pools
  #TODO: org load balancer monitors
  #TODO: org load balancer pools
  #TODO: load balancers
  private

  def date_rfc3339?(ts)
    begin
      DateTime.rfc3339(ts)
    rescue ArgumentError
      return false
    end
    true
  end

  def zone_id_check(zone_id)
    raise ("zone_id required") if zone_id.nil?
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
    JSON.parse(result.body)
  end

  def cf_get(path: nil, params: {})
    result = @cf_client.get do |request|
      request.url(API_BASE + path) unless path.nil?
      request.params = params unless params.nil?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    JSON.parse(result.body)
  end

  def cf_put(path: nil, data: nil)
    result = @cf_client.put do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.nil?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    JSON.parse(result.body)
  end

  def cf_patch(path: nil, data: {})
    result = @cf_client.patch do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.empty?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    JSON.parse(result.body)
  end

  def cf_delete(path: nil, data: {})
    result = @cf_client.delete do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.empty?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    JSON.parse(result.body)
  end

  def valid_setting?(name = nil)
    return false if name.nil?
    return false unless POSSIBLE_API_SETTINGS.include?(name)
    true
  end
end
