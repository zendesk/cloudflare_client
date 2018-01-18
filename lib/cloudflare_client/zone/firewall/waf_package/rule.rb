class CloudflareClient::Zone::Firewall::WAFPackage::Rule < CloudflareClient::Zone::Firewall::WAFPackage::Base
  VALID_ORDERS = %w[priority group_id description].freeze
  VALID_MODES  = %w[default disable simulate block challenge on off].freeze

  ##
  # waf_rules

  ##
  # list waf rules
  def list(mode: {}, priority: nil, match: 'all', order: 'priority', page: 1, per_page: 50, group_id: nil, description: nil, direction: 'desc')
    #FIXME: mode isn't documented in api, ask CF
    #FIXME: priority is read only?, ask CF
    params = {page: page, per_page: per_page}

    valid_value_check(:match, match, VALID_MATCHES)
    params[:match] = match

    valid_value_check(:order, order, VALID_ORDERS)
    params[:order] = order

    valid_value_check(:direction, direction, VALID_DIRECTIONS)
    params[:direction] = direction

    params[:group_id] unless group_id.nil?
    params[:description] unless description.nil?

    cf_get(path: "/zones/#{zone_id}/waf/packages/#{package_id}/rules", params: params)
  end

  ##
  # get a single waf rule
  def show(id:)
    id_check('id', id)

    cf_get(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/rules/#{id}")
  end

  ##
  # update a waf rule
  def update(id:, mode: 'on')
    id_check('id', id)
    valid_value_check(:mode, mode, VALID_MODES)

    cf_patch(path: "/zones/#{zone_id}/firewall/waf/packages/#{package_id}/rules/#{id}", data: {mode: mode})
  end
end
