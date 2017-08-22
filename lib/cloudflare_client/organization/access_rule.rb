class CloudflareClient::Organization::AccessRule < CloudflareClient::Organization
  VALID_MODES          = %w[block challenge whitelist].freeze
  VALID_CONFIG_TARGETS = %w[ip ip_range country_code].freeze
  VALID_ORDERS         = %w[configuration_target configuration_value mode].freeze

  ##
  # org level firewall rules
  #

  ##
  # list access rules
  def list(notes: nil, mode: nil, match: 'all', configuration_value: nil, order: nil, page: 1, per_page: 50, configuration_target: nil, direction: 'desc')
    params = {page: page, per_page: per_page}

    unless notes.nil?
      basic_type_check(:notes, notes, String)
      params[:notes] = notes
    end

    unless mode.nil?
      valid_value_check(:mode, mode, VALID_MODES)
      params[:mode] = mode
    end

    unless match.nil?
      valid_value_check(:match, match, VALID_MATCHES)
      params[:match] = match
    end

    params[:configuration_value] = configuration_value unless configuration_value.nil?

    #FIXME: check this against the api
    unless order.nil?
      valid_value_check(:order, order, VALID_ORDERS)
      params[:order] = order
    end

    unless configuration_target.nil?
      valid_value_check(:configuration_target, configuration_target, VALID_CONFIG_TARGETS)
      params[:configuration_target] = configuration_target
    end

    unless direction.nil?
      valid_value_check(:direction, direction, VALID_DIRECTIONS)
      params[:direction] = direction
    end

    cf_get(path: "/organizations/#{org_id}/firewall/access_rules/rules", params: params)
  end

  ##
  # create access rule
  def create(mode:, configuration:, notes: nil)
    non_empty_hash_check(:configuration, configuration)
    valid_value_check(:mode, mode, VALID_MODES)

    #TODO: validate config objects?
    data         = {mode: mode, configuration: configuration}
    data[:notes] = notes unless notes.nil?

    cf_post(path: "/organizations/#{org_id}/firewall/access_rules/rules", data: data)
  end

  ##
  # update access rule
  # def update
  #
  # end

  ##
  # delete org access rule
  def delete(id:)
    id_check('id', id)
    cf_delete(path: "/organizations/#{org_id}/firewall/access_rules/rules/#{id}")
  end
end
