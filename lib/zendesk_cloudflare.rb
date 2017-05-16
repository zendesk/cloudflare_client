##
# General class for the client
class CloudflareClient
  require 'json'
  require 'faraday'
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

  # zone settings section of the api

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

  # DNS methods

  private

  def build_client(params)
    raise('Missing auth_key') if params[:auth_key].nil?
    raise('Missing auth email') if params[:email].nil?
    client = Faraday.new(url:  API_BASE)
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

  def cf_put(path: nil)
    result = @cf_client.put do |request|
      request.url(API_BASE + path) unless path.nil?
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
