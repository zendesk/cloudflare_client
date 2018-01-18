class CloudflareClient::Zone::Firewall::AccessRule < CloudflareClient::Zone::Firewall
  VALID_MODES          = %w[block challenge whitelist].freeze
  VALID_SCOPE_TYPES    = %w[user organization zone].freeze
  VALID_CONFIG_TARGETS = %w[ip ip_range country].freeze
  VALID_ORDERS         = %w[scope_type configuration_target configuration_value mode].freeze
  VALID_CASCADES       = %w[none basic aggressive].freeze

  ##
  # firewall_access_rules_for_a_zone
  def list(notes: nil, mode: nil, match: nil, scope_type: nil, configuration_value: nil, order: nil, page: 1, per_page: 50, configuration_target: nil, direction: 'desc')
    params                       = {page: page, per_page: per_page}
    params[:notes]               = notes unless notes.nil?
    params[:configuration_value] = configuration_value unless configuration_value.nil?

    unless mode.nil?
      valid_value_check(:mode, mode, VALID_MODES)
      params[:mode] = mode
    end

    unless match.nil?
      valid_value_check(:match, match, VALID_MATCHES)
      params[:match] = match
    end

    unless scope_type.nil?
      valid_value_check(:scope_type, scope_type, VALID_SCOPE_TYPES)
      params[:scope_type] = scope_type
    end

    unless configuration_target.nil?
      valid_value_check(:configuration_target, configuration_target, VALID_CONFIG_TARGETS)
      params[:configuration_target] = configuration_target
    end

    unless direction.nil?
      valid_value_check(:direction, direction, VALID_DIRECTIONS)
      params[:direction] = direction
    end

    unless order.nil?
      valid_value_check(:order, order, VALID_ORDERS)
      params[:order] = order
    end

    cf_get(path: "/zones/#{zone_id}/firewall/access_rules/rules", params: params)
  end

  ##
  # create firewall access rule
  def create(mode:, configuration:, notes: nil)
    valid_value_check(:mode, mode, VALID_MODES)
    if configuration.is_a?(Hash)
      unless configuration.keys.map(&:to_sym).sort == [:target, :value]
        raise 'configuration must contain valid a valid target and value'
      end
    else
      raise 'configuration must be a valid configuration object'
    end

    data         = {mode: mode, configuration: configuration}
    data[:notes] = notes unless notes.nil?

    cf_post(path: "/zones/#{zone_id}/firewall/access_rules/rules", data: data)
  end

  ##
  # updates firewall_access_rule
  def update(id:, mode: nil, notes: nil)
    id_check('id', id)
    valid_value_check(:mode, mode, VALID_MODES) unless mode.nil?

    data         = {}
    data[:mode]  = mode unless mode.nil?
    data[:notes] = notes unless notes.nil?

    cf_patch(path: "/zones/#{zone_id}/firewall/access_rules/rules/#{id}", data: data)
  end

  ##
  # delete a firewall access rule
  def delete(id:, cascade: 'none')
    id_check('id', id)
    valid_value_check(:cascade, cascade, VALID_CASCADES)

    cf_delete(path: "/zones/#{zone_id}/firewall/access_rules/rules/#{id}")
  end
end
