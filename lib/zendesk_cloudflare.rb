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
  def organization(org_id:)
    id_check('org_id', org_id)
    cf_get(path: "/organizations/#{org_id}")
  end

  ##
  # update a given org (only supports name)
  def update_organization(org_id:, name: nil)
    id_check('org_id', org_id)
    data = {name: name} unless name.nil?
    cf_patch(path: "/organizations/#{org_id}", data: data)
  end

  ##
  # org members

  ##
  # list or members
  def organization_members(org_id:)
    id_check('org_id', org_id)
    cf_get(path: "/organizations/#{org_id}/members")
  end

  ##
  # org member details
  def organization_member(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_get(path: "/organizations/#{org_id}/members/#{id}")
  end

  ##
  # update org member roles
  def update_organization_member_roles(org_id:, id:, roles:)
    id_check('org_id', org_id)
    id_check('id', id)
    raise("roles must be an array of roles") unless roles.is_a?(Array)
    raise("roles cannot be empty") if roles.empty?
    data = {roles: roles}
    cf_patch(path: "/organizations/#{org_id}/members/#{id}", data: data)
  end

  ##
  # remove org member
  def remove_org_member(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_delete(path: "/organizations/#{org_id}/members/#{id}")
  end


  ##
  # org invites

  ##
  # create an org invite
  def create_organization_invite(org_id:, email:, roles:, auto_accept: nil)
    id_check('org_id', org_id)
    id_check('email', email)
    raise("roles must be an array of roles") unless roles.is_a?(Array)
    raise("roles cannot be empty") if roles.empty?
    unless auto_accept.nil?
      raise("auto_accept must be a boolean value") unless (auto_accept == true || auto_accept == false)
    end
    data = {invited_member_email: email, roles: roles}
    cf_post(path: "/organizations/#{org_id}/invites", data: data)
  end

  ##
  # org invites
  def organization_invites(org_id:)
    id_check('org_id', org_id)
    cf_get(path: "/organizations/#{org_id}/invites")
  end

  ##
  # org invite details
  def organization_invite(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_get(path: "/organizations/#{org_id}/invites/#{id}")
  end

  ##
  # update an organization invites roles
  def updates_organization_invite_roles(org_id:, id:, roles:)
    id_check('org_id', org_id)
    id_check('id', id)
    raise("roles must be an array of roles") unless roles.is_a?(Array)
    raise("roles cannot be empty") if roles.empty?
    data = {roles: roles}
    cf_patch(path: "/organizations/#{org_id}/invites/#{id}", data: data)
  end

  ##
  # cancel an organization invite
  def cancel_organization_invite(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_delete(path: "/organizations/#{org_id}/invites/#{id}")
  end

  ##
  # org roles
  #

  ##
  # list all organization roles
  def organization_roles(org_id:)
    id_check('org_id', org_id)
    cf_get(path: "/organizations/#{org_id}/roles")
  end

  ##
  # get details of an organization role
  def organization_role(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_get(path: "/organizations/#{org_id}/roles/#{id}")
  end

  ##
  # org level firewall rules
  #

  ##
  # list access rules
  def org_level_firewall_rules(org_id:, notes: nil, mode: nil, match: 'all', configuration_value: nil, order: nil, page: 1, per_page: 50, configuration_target: nil, direction: "desc")
    id_check('org_id', org_id)
    params = {page: page, per_page: per_page}
    unless mode.nil?
      params[:mode] = mode if %w[block challenge whitelist].include?(mode)
    end
    params[:match] = match if (match == "all" || match == "any")
    params[:configuration_value] = configuration_value if ['IP', 'range', 'country_code'].include?(configuration_value)
    #FIXME: check this against the api
    params[:order] = order if %w[configuration_target configuration_value mode].include?(order)
    params[:configuration_target] = configuration_target if %w[ip range country ].include?(configuration_target)
    params[:direction] = direction if (direction == 'asc' || direction == 'desc')
    cf_get(path: "/organizations/#{org_id}/firewall/access_rules/rules", params: params)
  end

  ##
  # list access rules
  def create_org_access_rule(org_id:, mode: nil, configuration: nil, notes: nil)
    id_check('org_id', org_id)
    unless configuration.nil?
      raise("configuration must be a hash") unless configuration.is_a?(Hash)
      raise("configuration cannot be empty") if configuration.empty?
    end
    unless mode.nil?
      raise "mode must be one of block, challenge, whitelist" unless %w[block challenge whitelist].include?(mode)
    end
    #TODO: validate config objects?
    data = {}
    data[:mode] = mode unless mode.nil?
    data[:configuration] = configuration unless configuration.nil?
    data[:notes] = notes unless notes.nil?
    cf_post(path: "/organizations/#{org_id}/firewall/access_rules/rules", data: data)
  end

  ##
  # delete org access rule
  def delete_org_access_rule(org_id:, id:)
    id_check('org_id', org_id)
    id_check('id', id)
    cf_delete(path: "/organizations/#{org_id}/firewall/access_rules/rules/#{id}")
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

  def date_iso8601?(ts)
    begin
      DateTime.iso8601(ts)
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
    JSON.parse(result.body)
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
