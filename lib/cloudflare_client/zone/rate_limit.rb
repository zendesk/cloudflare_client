class CloudflareClient::Zone::RateLimit < CloudflareClient::Zone::Base
  DOC_URL = 'https://api.cloudflare.com/#rate-limits-for-a-zone-create-a-ratelimit'.freeze

  ##
  # rate_limits_for_a_zone

  ##
  # list zone rate limits
  def list(page: 1, per_page: 50)
    params = {page: page, per_page: per_page}

    cf_get(path: "/zones/#{zone_id}/rate_limits", params: params)
  end

  ##
  # Create a zone rate limit
  def create(match:, threshold:, period:, action:, id: nil, disabled: nil, description: nil, bypass: nil)
    common_checks(match, action, threshold, period)

    data      = {match: match, threshold: threshold, period: period, action: action}
    data[:id] = id unless id.nil?

    unless disabled.nil?
      valid_value_check(:disabled, disabled, [true, false])
      data[:disabled] = disabled
    end

    cf_post(path: "/zones/#{zone_id}/rate_limits", data: data)
  end

  ##
  # get details for a zone rate limit
  def show(id:)
    id_check('id', id)

    cf_get(path: "/zones/#{zone_id}/rate_limits/#{id}")
  end

  ##
  # update zone rate limit
  def update(id:, match:, action:, threshold:, period:, disabled: nil, description: nil, bypass: nil)
    id_check('id', id)
    common_checks(match, action, threshold, period)

    data               = {match: match, threshold: threshold, period: period, action: action}
    data[:id]          = id unless id.nil?
    data[:description] = description unless description.nil?

    unless disabled.nil?
      valid_value_check(:disabled, disabled, [true, false])
      data[:disabled] = disabled
    end

    cf_put(path: "/zones/#{zone_id}/rate_limits/#{id}", data: data)
  end

  ##
  # delete zone rate limit
  def delete(id:)
    id_check('id', id)

    cf_delete(path: "/zones/#{zone_id}/rate_limits/#{id}")
  end

  private

  def common_checks(match, action, threshold, period)
    raise "match must be a match object #{DOC_URL}" unless match.is_a?(Hash)
    raise "action must be a action object #{DOC_URL}" unless action.is_a?(Hash)
    raise 'threshold must be between 1 86400' if !threshold.is_a?(Integer) || !threshold.between?(1, 86400)
    raise 'period must be between 1 86400' if !period.is_a?(Integer) || !period.between?(1, 86400)
  end
end
