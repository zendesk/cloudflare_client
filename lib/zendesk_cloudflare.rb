##
# General class for the client
class CloudflareClient
  require 'json'
  require 'faraday'
  require 'date'
  require 'byebug'

  API_BASE = 'https://api.cloudflare.com/client/v4'.freeze
  VALID_BUNDLE_METHODS = %w[ubiquitous optimal force].freeze

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
  def zones(name: nil, status: nil, per_page: 50, page: 1)
    params = {}
    params[:per_page] = per_page
    params[:page]     = page
    params[:name]     = name unless name.nil?
    unless status.nil?
      valid_statuss = ['active', 'pending', 'initializing', 'moved', 'deleted', 'deactivated', 'read only']
      raise("status must be one of #{valid_statuss.flatten}") unless valid_statuss.include?(status)
    end
    cf_get(path: '/zones', params: params)
  end

  ##
  # create's a zone with a given name
  # create_zone(name: name_of_zone, jump_start: true|false (default true),
  # organization: {id: org_id, name: org_name})
  def create_zone(name:, jump_start: true, organization: { id: nil, name: nil })
    raise('Zone name required') if name.nil?
    unless organization[:id].nil? && organization[:name].nil
      org_data = organization.merge(status: 'active', permissions: ['#zones:read'])
    end
    data = { name: name, jump_start: jump_start, organization: org_data }
    cf_post(path: '/zones', data: data)
  end

  ##
  # request another zone activation (ssl) check
  # zone_activation_check(zone_id:)
  def zone_activation_check(zone_id:)
    raise('zone_id required') if zone_id.nil?
    cf_put(path: "/zones/#{zone_id}/activation_check")
  end

  ##
  # return all the details for a given zone_id
  # zone_details(zone_id: id_of_my_zone
  def zone(zone_id:)
    raise('zone_id required') if zone_id.nil?
    cf_get(path: "/zones/#{zone_id}")
  end

  ##
  # edit the properties of a zone
  # NOTE: some of these options require an enterprise account
  # edit_zone(zone_id: id_of_zone, paused: true|false,
  # vanity_name_servers: ['ns1.foo.bar', 'ns2.foo.bar'], plan: {id: plan_id})
  def edit_zone(zone_id:, paused: nil, vanity_name_servers: [], plan: { id: nil })
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
  def purge_zone_cache(zone_id:, tags: [], files: [], purge_everything: nil)
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
  def delete_zone(zone_id:)
    raise('zone_id required') if zone_id.nil?
    cf_delete(path: "/zones/#{zone_id}")
  end

  ##
  # return all settings for a given zone
  def zone_settings(zone_id:)
    raise('zone_id required') if zone_id.nil?
    cf_get(path: '/zones/#{zone_id}/settings')
  end

  ##
  # there are a lot of settings that can be returned.
  def zone_setting(zone_id:, name:)
    raise('zone_id required') if zone_id.nil?
    raise('setting_name not valid') if name.nil? || !valid_setting?(name)
    cf_get(path: "/zones/#{zone_id}/settings/#{name}")
  end

  ##
  # update 1 or more settings in a zone
  # settings: [{name: value: true},{name: 'value'}...]
  # https://api.cloudflare.com/#zone-settings-properties
  def update_zone_settings(zone_id:, settings: [])
    raise('zone_id required') if zone_id.nil?
    data = settings.map do |setting|
      raise("setting_name \"#{setting[:name]}\" not valid") unless valid_setting?(setting[:name])
      { id: setting[:name], value: setting[:value] }
    end
    data = { 'items': data }
    cf_patch(path: "/zones/#{zone_id}/settings", data: data)
  end

  #TODO: zone_rate_plans

  ##
  # DNS methods

  ##
  # Create a dns record
  def create_dns_record(zone_id:, name:, type:, content:, ttl: nil, proxied: nil)
    valid_types = ['A', 'AAAA', 'CNAME', 'TXT', 'SRV', 'LOC', 'MX', 'NS', 'SPF', 'read only']
    raise ("type must be one of #{valid_types.flatten}") unless valid_types.include?(type)
    data = {name: name, type: type, content: content}
    cf_post(path: "/zones/#{zone_id}/dns_records", data: data)
  end

  ##
  # list/search for dns records in a given zone
  def dns_records(zone_id:, name: nil, content: nil, per_page: 50, page_no: 1, order: "type", match: "all", type: nil)
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
  def dns_record(zone_id:, id:)
    id_check("zone_id", zone_id)
    id_check("dns record id", id)
    cf_get(path: "/zones/#{zone_id}/dns_records/#{id}")
  end

  ##
  # update a dns record.
  # zone_id, id, type, and name are all required.  ttl and proxied are optional
  def update_dns_record(zone_id:, id:, type:, name:, content:, ttl: nil, proxied: nil)
    id_check('zone_id', zone_id)
    id_check('dns record id', id)
    id_check('dns record type', type)
    id_check('dns record name', name)
    id_check('dns record content', content)
    raise("must suply type, name, and content") if (type.nil? || name.nil? || content.nil?)
    data = {type: type, name: name, content: content}
    data[:ttl] = ttl unless ttl.nil?
    data[:proxied] = proxied unless proxied.nil?
    cf_put(path: "/zones/#{zone_id}/dns_records/#{id}", data: data)
  end

  ##
  # delete a dns record
  # zone_id, id, type, and name are all required.  ttl and proxied are optional
  def delete_dns_record(zone_id:, id:)
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
  def railgun_connections(zone_id:)
    id_check('zone_id', zone_id)
    cf_get(path: "/zones/#{zone_id}/railguns")
  end

  ##
  # details of a single railgun
  def railgun_connection(zone_id:, id:)
    raise ("zone_id required") if zone_id.nil?
    raise ("railgun id required") if id.nil?
    cf_get(path: "/zones/#{zone_id}/railguns/#{id}")
  end

  ##
  # test a railgun connection
  def test_railgun_connection(zone_id:, id:)
    raise ("zone_id required") if zone_id.nil?
    raise ("railgun id required") if id.nil?
    cf_get(path: "/zones/#{zone_id}/railguns/#{id}/diagnose")
  end

  ##
  # connect or disconnect a railgun
  def connect_railgun(zone_id:, id:, connected:)
    id_check("zone_id", zone_id)
    raise ("railgun id required") if id.nil?
    raise ("connected must be true or false") if (connected != true && connected != false)
    data = {connected: connected}
    cf_patch(path: "/zones/#{zone_id}/railguns/#{id}", data: data)
  end

  ##
  # zone analytics (free, pro, business, enterprise)

  ##
  # return dashboard data for a given zone or colo
  def zone_analytics_dashboard(zone_id:)
    id_check("zone_id", zone_id)
    cf_get(path: "/zones/#{zone_id}/analytics/dashboard")
  end

  ##
  # creturn analytics for colos for a time window.
  # since and untill must be RFC 3339 timestamps
  # TODO: support continuous
  def colo_analytics(zone_id:, since_ts: nil, until_ts: nil)
    id_check("zone_id", zone_id)
    raise("since_ts must be a valid timestamp") if since_ts.nil? || !date_rfc3339?(since_ts)
    raise("until_ts must be a valid timestamp") if until_ts.nil? || !date_rfc3339?(until_ts)
    cf_get(path: "/zones/#{zone_id}/analytics/dashboard")
  end

  ##
  # DNS analytics

  ##
  # return a table of analytics
  def dns_analytics_table(zone_id:)
    id_check("zone_id", zone_id)
    cf_get(path: "/zones/#{zone_id}/dns_analytics/report")
  end

  ##
  # return analytics by time
  def dns_analytics_bytime(zone_id:, dimensions: [], metrics: [], sort: [], filters: [], since_ts: nil, until_ts: nil, limit: 100, time_delta: "hour")
    id_check("zone_id", zone_id)
    # TODO: what are valid dimensions?
    # TODO: what are valid metrics?
    unless since_ts.nil?
      raise("since_ts must be a valid timestamp") if !date_rfc3339?(since_ts)
    end
    unless until_ts.nil?
      raise("until_ts must be a valid timestamp") if !date_rfc3339?(until_ts)
    end
    params = {limit: limit, time_delta: time_delta}
    params["since"] = since_ts
    params["until"] = until_ts
    cf_get(path: "/zones/#{zone_id}/dns_analytics/report/bytime", params: params)
  end

  ##
  # Railgun methods

  ##
  # create_railgun(name: 'name of railgun')
  def create_railgun(name:)
    raise ("Railgun name cannot be nil") if name.nil?
    data = {name: name}
    cf_post(path: '/railguns', data: data)
  end

  ##
  # Get all the railguns
  def railguns(page: 1, per_page: 50, direction: "desc")
    raise ("direction must be either desc | asc") if (direction != "desc" && direction != "asc")
    params = {page: page, per_page: per_page, direction: direction}
    cf_get(path: '/railguns', params: params)
  end

  ##
  # Get a single railgun
  def railgun(id:)
    raise ("must provide the id of the railgun") if id.nil?
    cf_get(path: "/railguns/#{id}")
  end

  ##
  # Get CF zones associated with a railgun
  def railgun_zones(id:)
    raise ("must provide the id of the railgun") if id.nil?
    cf_get(path: "/railguns/#{id}/zones")
  end

  ##
  # Get CF zones associated with a railgun
  def railgun_enabled(id:, enabled:)
    raise ("must provide the id of the railgun") if id.nil?
    raise ("enabled must be true | false") if id.nil? || (enabled != false && enabled != true)
    data = {enabled: enabled}
    cf_patch(path: "/railguns/#{id}", data: data)
  end

  ##
  # delete a railgun
  def delete_railgun(id:)
    raise ("must provide the id of the railgun") if id.nil?
    cf_delete(path: "/railguns/#{id}")
  end

  ##
  # Custom pages for a zone
  ##
  # custom_pages list all avaialble custom_pages
  def custom_pages(zone_id:)
    id_check("zone_id", zone_id)
    cf_get(path: "/zones/#{zone_id}/custom_pages")
  end

  ##
  # custom_page details
  def custom_page(zone_id:, id:)
    id_check("zone_id", zone_id)
    raise("id must not be nil") if id.nil?
    cf_get(path: "/zones/#{zone_id}/custom_pages/#{id}")
  end

  ##
  # update_custom_page
  def update_custom_page(zone_id:, id:, url:, state:)
    id_check("zone_id", zone_id)
    id_check("id", id)
    id_check("url", url)
    raise("state must be either default | customized") if state != 'default' && state != 'customized'
    data = {url: url, state: state}
    cf_put(path: "/zones/#{zone_id}/custom_pages/#{id}", data: data)
  end

  ##
  # Custom SSL for a zone

  ##
  # create custom ssl for a zone
  def create_custom_ssl(zone_id:, certificate:, private_key:, bundle_method: nil)
    id_check("zone_id", zone_id)
    id_check('certificate', certificate)
    id_check('private_key', private_key)
    bundle_method_check(bundle_method) unless bundle_method.nil?
    # TODO: validate the cert/key using openssl?  Could be difficult if they are
    # privately generated
    data = {certificate: certificate, private_key: private_key}
    data[:bundle_method] = bundle_method unless bundle_method.nil?
    cf_post(path: "/zones/#{zone_id}/custom_certificates", data: data)
  end

  ##
  # list custom ssl configurations
  def ssl_configurations(zone_id:, page: 1, per_page: 50, order: "priority", direction: "asc", match: "all")
    id_check("zone_id", zone_id)
    valid_orders = ['status', 'issuer', 'priority', 'expires_on']
    raise ("order must be one of #{valid_orders.flatten}") unless valid_orders.include?(order)
    raise ('direction must be asc || desc') unless (direction == 'asc' || direction == 'desc')
    raise ('match must be all || any') unless (match == 'any' || match == 'all')
    params = {page: page, per_page: per_page}
    params[:match] = match
    params[:direction] = direction
    cf_get(path: "/zones/#{zone_id}/custom_certficates", params: params)
  end

  ##
  # details of a single config
  def ssl_configuration(zone_id:, configuration_id:)
    id_check("zone_id", zone_id)
    raise("ssl configuration id required") if configuration_id.nil?
    cf_get(path: "/zones/#{zone_id}/custom_certificates/#{configuration_id}")
  end

  ##
  # updates a custom ssl record
  def update_ssl_configuration(zone_id:, id:, private_key: nil, certificate: nil, bundle_method: nil)
    id_check("zone_id", zone_id)
    id_check("id", id)
    id_check("private_key must be provided") if private_key.nil?
    bundle_method_check(bundle_method)
    data = {private_key: private_key, certificate: certificate, bundle_method: bundle_method}
    cf_patch(path: "/zones/#{zone_id}/custom_certificates/#{id}", data: data)
  end

  ##
  # re-prioritize ssl certs data = [{id: "cert_id", priority: 2}, {id: "cert_id", priority: 1}]
  def prioritize_ssl_configurations(zone_id:, data: [])
    id_check("zone_id", zone_id)
    raise("must provide an array of certifiates and priorities") if data.empty?
    cf_put(path: "/zones/#{zone_id}/custom_certificates/prioritize", data: data)
  end

  ##
  # delete a custom ssl cert
  def delete_ssl_configuration(zone_id:, id:)
    id_check("zone_id", zone_id)
    id_check("id", id)
    cf_delete(path: "/zones/#{zone_id}/custom_certificates/#{id}")
  end

  ##
  # custom_hostnames

  ##
  # create custom_hostname
  # Note, custom_metadata may only work for enterprise or better customers
  def create_custom_hostname(zone_id:, hostname:, method: 'http', type: 'dv', custom_metadata: {})
    #FIXME: implement checks for the custom_metedata/find out of it's going to be exposed to anyone else
#"custom_metadata":{"origin_override":"hostname.zendesk.com"}
#"custom_metadata":{"hsts_enabled":"true"}
#"custom_metadata":{"hsts_enabled":"true","custom_maxage":value}
    id_check("zone_id", zone_id)
    id_check('hostname', hostname)
    valid_http_values = %w[http email cname]
    raise("method must be one of #{valid_http_values.flatten}") unless valid_http_values.include?(method)
    raise("type must be either dv or read only") unless (type == 'dv' || type == 'read only')
    data = {hostname: hostname, ssl: {method: method, type: type}}
    data[:custom_metadata] = custom_metadata unless custom_metadata.empty?
    cf_post(path: "/zones/#{zone_id}/custom_hostnames", data: data)
  end

  ##
  # list custom_hostnames
  def custom_hostnames(zone_id:, hostname: nil, id: nil, page: 1, per_page: 50, order: "ssl", direction: "desc", ssl: 0)
    id_check("zone_id", zone_id)
    if (!hostname.nil? && !id.nil?)
      raise("cannot use hostname and id")
    end
    raise("order must be ssl or ssl_status") if (order != "ssl" && order != "ssl_status")
    raise("direction must be either asc or desc)") if (direction != 'asc' && direction != 'desc')
    raise("ssl must be either 0 or 1") if (ssl != 0 && ssl != 1)
    params = {page: page, per_page: per_page, order: order, direction: direction, ssl: ssl}
    params[:hostname] = hostname unless hostname.nil?
    params[:id] = id unless id.nil?
    cf_get(path: "/zones/#{zone_id}/custom_hostnames", params: params)
  end

  ##
  # details of a custom hostname
  def custom_hostname(zone_id:, id:)
    id_check("zone_id", zone_id)
    id_check("id", id)
    cf_get(path: "/zones/#{zone_id}/custom_hostnames/#{id}")
  end

  ##
  # update a custom hosntame
  def update_custom_hostname(zone_id:, id:, method: nil, type: nil, custom_metadata: nil)
    valid_methods = %w[http email cname]
    valid_types = ['read only', 'dv']
    id_check('zone_id', zone_id)
    id_check('id', id)
    data = {}
    unless (type.nil? && method.nil?)
      raise("method must be one of #{valid_methods.flatten}") unless valid_methods.include?(method)
      raise("type must be one of #{valid_types.flatten}") unless valid_types.include?(type)
      data[:ssl] = {method: method, type: type}
    end
    unless custom_metadata.nil?
      raise("custom_metadata must be an object") unless custom_metadata.is_a?(Hash)
      data[:custom_metadata] = custom_metadata
    end
    cf_patch(path: "/zones/#{zone_id}/custom_hostnames/#{id}", data: data)
  end

  ##
  # delete a custom hostname and ssl certs
  def delete_custom_hostname(zone_id:, id:)
    id_check('zone_id', zone_id)
    id_check('id', id)
    cf_delete(path: "/zones/#{zone_id}/custom_hostnames/#{id}")
  end

  ##
  # keyless_ssl

  ##
  # create a keyless ssl config
  def create_keyless_ssl_config(zone_id:, host:, port:, certificate:, name: nil, bundle_method: "ubiquitous")
    id_check("zone_id", zone_id)
    raise('host required') if host.nil?
    raise('certificate required') if certificate.nil?
    bundle_method_check(bundle_method)
    data = {host: host, port: port, certificate: certificate, bundle_method: bundle_method}
    data[:name] = name + ' Keyless SSL' unless name.nil?
    cf_post(path: "/zones/#{zone_id}/keyless_certificates", data: data)
  end

  ##
  # list all the keyless ssl configs
  def keyless_ssl_configs(zone_id:)
    id_check("zone_id", zone_id)
    cf_get(path: "/zones/#{zone_id}/keyless_certificates")
  end

  ##
  # details of a keyless_ssl_config
  def keyless_ssl_config(zone_id:, id:)
    id_check('zone_id', zone_id)
    id_check('id', id)
    cf_get(path: "/zons/#{zone_id}/keyless_certificates/#{id}")
  end

  ##
  # updates a keyless ssl config
  def update_keyless_ssl_config(zone_id:, id:, host: nil, name: nil, port: nil, enabled: nil)
    id_check('zone_id', zone_id)
    id_check('id', id)
    unless enabled.nil?
      raise ("enabled must be true||false") unless (enabled == true || enabled == false)
    end
    data = {}
    data[:host] = host unless host.nil?
    data[:name] = host + " Keyless ssl" unless name.nil?
    data[:port] = port unless name.nil?
    data[:enabled] = port unless enabled.nil?
    cf_patch(path: "/zones/#{zone_id}/keyless_certificates/#{id}", data: data)
  end

  ##
  # delete a custom_ssl_config
  def delete_keyless_ssl_config(zone_id:, id:)
    id_check('zone_id', zone_id)
    id_check('id', id)
    cf_delete(path: "/zones/#{zone_id}/keyless_certificates/#{id}")
  end

  ##
  # page_rules_for_a_zone

  ##
  # create zone_page_rule
  def create_zone_page_rule(zone_id:, targets:, actions:, priority: 1, status: 'disabled')
    id_check("zone_id", zone_id)
    if (!targets.is_a?(Array) || targets.empty?)
      raise("targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule")
    end
    if (!actions.is_a?(Array) || actions.empty?)
      raise("actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule")
    end
    raise("status must be disabled||active") if (status != "disabled" && status != "active")
    data = {targets: targets, actions: actions, priority: priority, status: status}
    cf_post(path: "/zones/#{zone_id}/pagerules", data: data)
  end

  ##
  # list all the page rules for a zone
  def zone_page_rules(zone_id:, status: 'disabled', order: 'priority', direction: 'desc', match: 'all')
    id_check("zone_id", zone_id)
    raise ('status must be either active||disabled') unless (status == 'active' || status == 'disabled')
    raise ('order must be either status||priority') unless (order == 'status' || order == 'priority')
    raise ('direction must be either asc||desc') unless (direction == 'asc' || direction == 'desc')
    raise ('match must be either any||all') unless (match == 'any' || match == 'all')
    params = {status: status, order: order, direction: direction, match: match}
    cf_get(path: "/zones/#{zone_id}/pagerules", params: params)
  end

  ##
  # page rule details
  def zone_page_rule(zone_id:, id:)
    id_check("zone_id", zone_id)
    id_check('id', id)
    cf_get(path: "/zones/#{zone_id}/pagerules/#{id}")
  end

  #TODO: do we need upate, looks the same as change

  ##
  # update a page rule
  def update_zone_page_rule(zone_id:, id:, targets: [], actions: [], priority: 1, status: 'disabled')
    id_check('zone_id', zone_id)
    id_check('id', id)
    if (!targets.is_a?(Array) || targets.empty?)
      raise("targets must be an array of targes https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule")
    end
    if (!actions.is_a?(Array) || actions.empty?)
      raise("actions must be an array of actions https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule")
    end
    raise("status must be disabled||active") if (status != "disabled" && status != "active")
    data = {targets: targets, actions: actions, priority: priority, status: status}
    cf_patch(path: "/zones/#{zone_id}/pagerules/#{id}", data: data)
  end

  ##
  # delete a zone page rule
  def delete_zone_page_rule(zone_id:, id:)
    id_check("zone_id", zone_id)
    raise ('zone page rule id required') if id.nil?
    cf_delete(path: "/zones/#{zone_id}/pagerules/#{id}")
  end

  ##
  # rate_limits_for_a_zone

  ##
  # list zone rate limits
  def zone_rate_limits(zone_id:, page: 1, per_page: 50)
    id_check("zone_id", zone_id)
    params = {page: page, per_page: per_page}
    cf_get(path: "zones/#{zone_id}", params: params)
  end

  ##
  # Create a zone rate limit
  def create_zone_rate_limit(zone_id:, match:, threshold:, period:, action:, id: nil, disabled: nil, description: nil, bypass: nil)
    doc_url = 'https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit'
    id_check("zone_id", zone_id)
    raise("match must be a match object #{doc_url}") unless match.is_a?(Hash)
    raise("action must be a action object #{doc_url}") unless action.is_a?(Hash)
    raise('threshold must be between 1 86400') if (!threshold.is_a?(Integer) || !threshold.between?(1, 86400))
    raise('period must be between 1 86400') if (!period.is_a?(Integer) || !period.between?(1, 86400))
    unless disabled.nil?
      raise('disabled must be true || false') unless (disabled == true || disabled == false)
    end
    data = {match: match, threshold: threshold, period: period, action: action}
    # optional params
    data[:id] = id unless id.nil?
    data[:disabled] = disabled unless id.nil?
    cf_post(path: "/zones/#{zone_id}/rate_limits", data: data)
  end

  ##
  # get details for a zone rate limit
  def zone_rate_limit(zone_id:, id:)
    id_check('zone_id', zone_id)
    id_check('id', id)
    cf_get(path: "/zones/#{zone_id}/rate_limits/#{id}")
  end

  ##
  # update zone rate limit
  def update_zone_rate_limit(zone_id:, id:, match:, threshold:, period:, action:, disabled: nil, description: nil, bypass: nil)
    id_check('zone_id', zone_id)
    id_check('id', id)
    doc_url = 'https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit'
    raise("match must be a match object #{doc_url}") unless match.is_a?(Hash)
    raise('threshold must be between 1 86400') if (!threshold.is_a?(Integer) || !threshold.between?(1, 86400))
    raise("action must be a action object #{doc_url}") unless action.is_a?(Hash)
    raise('period must be between 1 86400') if (!period.is_a?(Integer) || !period.between?(1, 86400))
    unless disabled.nil?
      raise('disabled must be true || false') unless (disabled == true || disabled == false)
    end
    data = {match: match, threshold: threshold, period: period, action: action}
    # optional params
    data[:id] = id unless id.nil?
    data[:disabled] = disabled unless id.nil?
    data[:description] = description unless description.nil?
    cf_put(path: "/zones/#{zone_id}/rate_limits/#{id}", data: data)
  end

  ##
  # delete zone rate limit
  def delete_zone_rate_limit(zone_id:, id:)
    id_check('zone_id', zone_id)
    id_check('zone rate limit id', id)
    cf_delete(path: "/zones/#{zone_id}/rate_limits/#{id}")
  end

  ##
  # firewall_access_rules_for_a_zone
  def firewall_access_rules(zone_id:, notes: nil, mode: nil, match: nil, scope_type: nil, configuration_value: nil, order: nil, page: 1, per_page: 50, configuration_target: nil, direction: 'desc')
    id_check('zone_id', zone_id, )
    params = {page: page, per_page: per_page}
    params[:notes] = notes unless notes.nil?
    unless mode.nil?
      raise("mode can only be one of block, challenge, whitelist") unless %w[block challenge whitelist].include?(mode)
      params[:mode] = mode
    end
    unless match.nil?
      raise("match can only be one either all || any") unless %w[all any].include?(match)
      params[:match] = match
    end
    unless scope_type.nil?
      raise("scope_type can only be one of user, organization, zone") unless %w[user organization zone].include?(scope_type)
      params[:scope_type] = scope_type
    end
    params[:configuration_value] = configuration_value unless configuration_value.nil?
    unless configuration_target.nil?
      possible_targets = %w[ip ip_range country]
      unless (possible_targets.include?(configuration_target))
        raise("configuration_target can only be one #{possible_targets.flatten}")
      end
      params[:configuration_target] = configuration_target
    end
    unless direction.nil?
      raise("direction must be either asc || desc") unless %w[asc desc].include?(direction)
      params[:direction] = direction
    end
    cf_get(path: "/zones/#{zone_id}/firewall/access_rules/rules", params: params)
  end

  ##
  # create firewall access rule
  def create_firewall_access_rule(zone_id:, mode:, configuration:, notes: nil)
    id_check('zone_id', zone_id)
    raise("mode must be one of block, challenge, whitlist") unless %w[block challenge whitelist].include?(mode)
    #https://api.cloudflare.com/#firewall-access-rule-for-a-zone-create-access-rule
    if configuration.is_a?(Hash)
      raise("configuration must contain valid a valid target and value") unless configuration.keys.sort == [:target, :value]
    else
      raise("configuration must be a valid configuration object")
    end
    data = {mode: mode, configuration: configuration}
    data[:notes] = notes unless notes.nil?
    cf_post(path: "/zones/#{zone_id}/firewall/access_rules/rules", data: data)
  end

  ##
  # updates firewall_access_rule
  def update_firewall_access_rule(zone_id:, id:, mode: nil,  notes: nil)
    id_check('zone_id', zone_id)
    id_check('id', id)
    unless mode.nil?
      raise("mode must be one of block, challenge, whitlist") unless %w[block challenge whitelist].include?(mode)
    end
    data = {}
    data[:mode] = mode unless mode. nil?
    data[:notes] = notes unless notes.nil?
    cf_patch(path: "/zones/#{zone_id}/firewall/access_rules/rules/#{id}", data: data)
  end

  ##
  # delete a firewall access rule
  def delete_firewall_access_rule(zone_id:, id:, cascade: 'none')
    id_check('zone_id', zone_id)
    id_check('id', id)
    raise("cascade must be one of none, basic, aggressive") unless %w[none basic aggressive].include?(cascade)
    cf_delete(path: "/zones/#{zone_id}/firewall/access_rules/rules/#{id}")
  end

  ##
  # waf_rule_packages
  def waf_rule_packages(zone_id:, name: nil, page: 1, per_page: 50, order: 'status', direction: 'desc', match: 'all')
    id_check('zone_id', zone_id)
    params = {page: page, per_page: per_page}
    params[:name] = name unless name.nil?
    raise ('order must be either status or name') unless (order == 'status' || order == 'name')
    params[:order] = order
    raise ('direction must be either asc or desc') unless (direction == "asc" || direction == "desc")
    params[:direction] = direction
    raise ('match must be either all or any') unless (match == "all" || match == "any")
    params[:match] = match
    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages", params: params)
  end

  ##
  # details of a single package
  def waf_rule_package(zone_id:, id:)
    id_check('zone_id', zone_id)
    id_check('id', id)
    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{id}")
  end

  ##
  # change anomoly detection of waf package
  def change_waf_rule_anomoly_detection(zone_id:, id:, sensitivity: 'high', action_mode: 'challange')
    id_check('zone_id', zone_id)
    id_check('id', id)
    raise('sensitivity must be one of high, low, off') unless %w[high low off].include?(sensitivity)
    raise('action_mode must be one of simulate, block or challenge') unless %w[simulate block challenge].include?(action_mode)
    data = {sensitivity: sensitivity, action_mode: action_mode}
    cf_patch(path: "/zones/#{zone_id}/firewall/waf/packages/#{id}", data: data)
  end

  ##
  # waf_rule_groups
  def waf_rule_groups(zone_id:, package_id:, name: nil, mode: 'on', rules_count: 0, page: 1, per_page: 50, order: 'mode', direction: 'desc', match: 'all')
    id_check('zone_id', zone_id)
    id_check('package_id', package_id)
    params = {page: page, per_page: per_page}
    raise("mode must be one of on or off") if (mode != 'on' && mode != 'off')
    params[:mode] = mode
    #FIXME: rules_count doesn't make any sense, ask CF
    raise('order must be one of mode or rules_count') if (order != 'mode' && order != 'rules_count')
    params[:order] = order
    raise('direction must be one of asc or desc') if (direction != 'asc' && direction != 'desc')
    params[:direction] = direction
    raise('match must be either all or any') if (match != 'any' && match != 'all')
    params[:match] = match
    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups", params: params)
  end

  ##
  # details of a waf rule group
  def waf_rule_group(zone_id:, package_id:, id:)
    id_check('zone_id', zone_id)
    id_check('package_id', package_id)
    id_check('id', id)
    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups/#{id}")
  end

  ##
  # updates a waf rule group
  def update_waf_rule_group(zone_id:, package_id:, id:, mode: 'on')
    id_check('zone_id', zone_id)
    id_check('package_id', package_id)
    id_check('id', id)
    raise('mode must be either on or off') if (mode != 'on' && mode != 'off')
    cf_patch(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups/#{id}", data: {mode: mode})
  end


  ##
  # waf_rules

  ##
  # list waf rules
  def waf_rules(zone_id:, package_id:, mode: {}, priority: nil, match: 'all', order: 'priority', page: 1, per_page: 50, group_id: nil, description: nil, direction: 'desc')
    id_check('zone_id', zone_id)
    id_check('package_id', package_id)
    #FIXME: mode isn't documented in api, ask CF
    #FIXME: priority is read only?, ask CF
    params = {page: page, per_page: per_page}
    match_check(match)
    params[:match] = match
    raise("order must be one of priority, group_id, description") unless %w[priority group_id description].include?(order)
    params[:order] = order
    params[:group_id] unless group_id.nil?
    params[:description] unless description.nil?
    direction_check(direction)
    params[:direction] = direction
    cf_get(path: "/zones/#{zone_id}/waf/packages/#{package_id}/rules", params: params)
  end

  ##
  # get a single waf rule
  def waf_rule(zone_id:, package_id:, id:)
    id_check('zone_id', zone_id)
    id_check('package_id', package_id)
    id_check('id', id)
    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/rules/#{id}")
  end

  ##
  # update a waf rule
  def update_waf_rule(zone_id:, package_id:, id:, mode: 'on')
    id_check('zone_id', zone_id)
    id_check('package_id', package_id)
    id_check('id', id)
    unless %w[default disable simulate block challenge on off].include?(mode)
      raise("mode must be one of default, disable, simulate, block, challenge, on, off")
    end
    cf_patch(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/rules/#{id}", data: {mode: mode})
  end

  ##
  #analyze_certificate

  ##
  # analyze a certificate
  def analyze_certificate(zone_id:, certificate: nil, bundle_method: 'ubiquitous')
    id_check('zone_id', zone_id)
    data = {}
    data[:certificate] = certificate unless certificate.nil?
    bundle_method_check(bundle_method)
    data[:bundle_method] = bundle_method
    cf_post(path: "/zones/#{zone_id}/ssl/analyze", data: data)
  end




  ##
  # certificate_packs

  ##
  # list all certificate packs
  def certificate_packs(zone_id:)
    id_check('zone_id', zone_id)
    cf_get(path: "/zones/#{zone_id}/ssl/certificate_packs")
  end

  ##
  # re-order certificate packs
  def order_certificate_packs(zone_id:, hosts: nil)
    unless (hosts.nil?)
      raise("hosts must be an array of hostnames") if (!hosts.is_a?(Array) || hosts.empty?)
    end
    data = {host: [hosts]}
    # TODO: test against api
    cf_post(path: "/zones/#{zone_id}/ssl/certificate_packs", data: data)
  end

  ##
  # edit a certificate pack
  def update_certificate_pack(zone_id:, id:, hosts:)
    id_check('zone_id', zone_id)
    id_check('id', id)
    raise('hosts must be an array of hosts') unless (hosts.is_a?(Array) && !hosts.empty?)
    data = {hosts: hosts}
    cf_patch(path: "/zones/#{zone_id}/ssl/certificate_packs/#{id}", data: data)
  end

  ##
  #ssl_verification

  ##
  # get ssl verification
  def ssl_verification(zone_id:, retry_verification: nil)
    id_check('zone_id', zone_id)
    unless retry_verification.nil?
      raise("retry_verification is true or nil") unless retry_verification == true
      params = {retry: true}
    end
    cf_get(path: "/zones/#{zone_id}/ssl/verification", params: params)
  end



  ##
  #zone_subscription

  ##
  # get a zone subscription
  # FIXME: seems to throw a 404
  def zone_subscription(zone_id:)
    id_check('zone_id', zone_id)
    cf_get(path: "/zones/#{zone_id}/subscription")
  end

  ##
  # create a zone subscriptions
  # FIXME: api talks about lots of read only constrains
  def create_zone_subscription(zone_id:, component_values: [], rate_plan: {}, zone: {}, state: nil, id: nil, frequency: nil)
    id_check('zone_id', zone_id)
    possible_states = %w[Trial Provisioned Paid AwaitingPayment Cancelled Failed Expired]
    possible_frequencies = %w[weekly monthly quarterly yearly]
    unless state.nil?
      raise ("state must be one of #{possible_states.flatten}") unless possible_states.include?(state.capitalize)
    end
    unless frequency.nil?
      raise ("frequency must be one of #{possible_frequencies.flatten}") unless possible_frequencies.include?(frequency)
    end
    data = {zone: zone, state: state, currency: 'USD', frequency: frequency}
    cf_post(path: "/zones/#{zone_id}/subscription", data: data)
  end

  ##
  # update a zone subscription
  def update_zone_subscription(zone_id: )
    #FIXME: more read-only questions abound
  end


  ##
  #organizations
  #

  ##
  # get an org's details
  def organization(id:)
    id_check('id', id)
    cf_get(path: "/organizations/#{id}")
  end

  ##
  # update a given org (only supports name)
  def update_organization(id:, name: nil)
    id_check('id', id)
    data = {name: name} unless name.nil?
    cf_patch(path: "/organizations/#{id}", data: data)
  end





  #
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
    cf_get(path: "/zones/#{zone_id}/logs/requests", params: params, raw: true)
  end

  ##
  # get a single log entry by it's ray_id
  def get_log(zone_id:, ray_id:)
    cf_get(path: "/zones/#{zone_id}/logs/requests/#{ray_id}", raw: true)
  end

  ##
  # get all logs after a given ray_id.  end_time must be a valid unix timestamp
  def get_logs_since(zone_id:, ray_id:, end_time: nil, count: nil)
    params = {start_id: ray_id}
    unless end_time.nil?
      raise('end time must be a valid unix timestamp') unless valid_timestamp?(end_time)
      params[:end] = end_time
    end
    params[:count] = count unless count.nil?
    cf_get(path: "/zones/#{zone_id}/logs/requests/#{ray_id}", params: params, raw: true)
  end

  private

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

  def direction_check(direction)
    raise ("direction must be either asc or desc") if (direction != 'asc' && direction != 'desc')
  end

  def match_check(match)
    raise ("match must be either all or any") if (match != 'all' && match != 'any')
  end

  def date_rfc3339?(ts)
    begin
      DateTime.rfc3339(ts)
    rescue ArgumentError
      return false
    end
    true
  end

  def id_check(name, id)
    raise ("#{name} required") if id.nil?
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

  def cf_get(path: nil, params: {}, raw: nil)
    result = @cf_client.get do |request|
      request.url(API_BASE + path) unless path.nil?
      request.params = params unless params.nil?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless result.status == 200
    raw.nil? ? JSON.parse(result.body) : result.body
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
    valid_response_codes = [200, 202]
    result = @cf_client.patch do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.empty?
    end
    raise(JSON.parse(result.body).dig('errors').first.to_s) unless valid_response_codes.include?(result.status)
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
