require 'zendesk_cloudflare/zone/base'

class CloudflareClient::Zone::PageRule < CloudflareClient::Zone::Base
  VALID_STATUSES = %w[active disabled].freeze
  VALID_ORDERS   = %w[status priority].freeze
  VALID_MATCHES  = %w[any all].freeze
  DOC_URL        = 'https://api.cloudflare.com/#page-rules-for-a-zone-create-a-page-rule'.freeze

  ##
  # page_rules_for_a_zone

  ##
  # create zone_page_rule
  def create(targets:, actions:, priority: 1, status: 'disabled')
    raise "targets must be an array of targets #{DOC_URL}" if !targets.is_a?(Array) || targets.empty?
    raise "actions must be an array of actions #{DOC_URL}" if !actions.is_a?(Array) || actions.empty?
    valid_value_check(:status, status, VALID_STATUSES)

    data = {targets: targets, actions: actions, priority: priority, status: status}

    cf_post(path: "/zones/#{zone_id}/pagerules", data: data)
  end

  ##
  # list all the page rules for a zone
  def list(status: 'disabled', order: 'priority', direction: 'desc', match: 'all')
    valid_value_check(:status, status, VALID_STATUSES)
    valid_value_check(:order, order, VALID_ORDERS)
    valid_value_check(:direction, direction, VALID_DIRECTIONS)
    valid_value_check(:match, match, VALID_MATCHES)

    params = {status: status, order: order, direction: direction, match: match}

    cf_get(path: "/zones/#{zone_id}/pagerules", params: params)
  end

  ##
  # page rule details
  def show(id:)
    id_check('id', id)
    
    cf_get(path: "/zones/#{zone_id}/pagerules/#{id}")
  end

  #TODO: do we need upate, looks the same as change

  ##
  # update a page rule
  def update(id:, targets: [], actions: [], priority: 1, status: 'disabled')
    id_check('id', id)
    raise "targets must be an array of targets #{DOC_URL}" if !targets.is_a?(Array) || targets.empty?
    raise "actions must be an array of actions #{DOC_URL}" if !actions.is_a?(Array) || actions.empty?
    valid_value_check(:status, status, VALID_STATUSES)

    data = {targets: targets, actions: actions, priority: priority, status: status}

    cf_patch(path: "/zones/#{zone_id}/pagerules/#{id}", data: data)
  end

  ##
  # delete a zone page rule
  def delete(id:)
    id_check('id', id)

    cf_delete(path: "/zones/#{zone_id}/pagerules/#{id}")
  end
end
