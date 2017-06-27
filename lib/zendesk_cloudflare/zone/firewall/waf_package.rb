require 'zendesk_cloudflare/zone/firewall'

class CloudflareClient::Zone::Firewall::WAFPackage < CloudflareClient::Zone::Firewall
  VALID_ORDERS        = %w[status name].freeze
  VALID_SENSITIVITIES = %w[high low off].freeze
  VALID_ACTION_MODES  = %w[simulate block challenge].freeze

  ##
  # lists waf_rule_packages
  def list(name: nil, page: 1, per_page: 50, order: 'status', direction: 'desc', match: 'all')
    params        = {page: page, per_page: per_page}
    params[:name] = name unless name.nil?

    valid_value_check(:order, order, VALID_ORDERS)
    params[:order] = order

    valid_value_check(:direction, direction, VALID_DIRECTIONS)
    params[:direction] = direction

    valid_value_check(:match, match, VALID_MATCHES)
    params[:match] = match

    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages", params: params)
  end

  ##
  # shows details of a single package
  def show(id:)
    id_check('id', id)

    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{id}")
  end

  ##
  # changes the sensitivity and action for an anomaly detection type WAF rule package
  def update(id:, sensitivity: 'high', action_mode: 'challange')
    id_check('id', id)
    valid_value_check(:sensitivity, sensitivity, VALID_SENSITIVITIES)
    valid_value_check(:action_mode, action_mode, VALID_ACTION_MODES)

    data = {sensitivity: sensitivity, action_mode: action_mode}

    cf_patch(path: "/zones/#{zone_id}/firewall/waf/packages/#{id}", data: data)
  end
end
