require 'zendesk_cloudflare/zone/firewall/waf_package/base'

class CloudflareClient::Zone::Firewall::WAFPackage::RuleGroup < CloudflareClient::Zone::Firewall::WAFPackage::Base
  VALID_MODES = %w[on off]
  VALID_ORDERS = %w[mode rules_count]

  ##
  # waf_rule_groups
  def list(name: nil, mode: 'on', rules_count: 0, page: 1, per_page: 50, order: 'mode', direction: 'desc', match: 'all')
    params = {page: page, per_page: per_page}

    valid_value_check(:mode, mode, VALID_MODES)
    params[:mode] = mode

    #FIXME: rules_count doesn't make any sense, ask CF
    valid_value_check(:order, order, VALID_ORDERS)
    params[:order] = order

    valid_value_check(:direction, direction, VALID_DIRECTIONS)
    params[:direction] = direction

    valid_value_check(:match, match, VALID_MATCHES)
    params[:match] = match

    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups", params: params)
  end

  ##
  # details of a waf rule group
  def show(id:)
    id_check('id', id)

    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups/#{id}")
  end

  ##
  # updates a waf rule group
  def update(id:, mode: 'on')
    id_check('id', id)
    valid_value_check(:mode, mode, VALID_MODES)

    cf_patch(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/groups/#{id}", data: {mode: mode})
  end
end
