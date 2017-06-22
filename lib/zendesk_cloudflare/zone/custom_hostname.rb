require 'zendesk_cloudflare/zone/base'

class CloudflareClient::Zone::CustomHostname < CloudflareClient::Zone::Base
  VALID_METHODS    = %w[http email cname].freeze
  VALID_TYPES      = ['read only', 'dv'].freeze
  VALID_ORDERS     = %w[ssl ssl_status].freeze
  VALID_DIRECTIONS = %w[asc desc].freeze

  ##
  # custom_hostnames

  ##
  # create custom_hostname
  # Note, custom_metadata may only work for enterprise or better customers
  def create(hostname:, method: 'http', type: 'dv', custom_metadata: {})
    #FIXME: implement checks for the custom_metedata/find out of it's going to be exposed to anyone else
    #"custom_metadata":{"origin_override":"hostname.zendesk.com"}
    #"custom_metadata":{"hsts_enabled":"true"}
    #"custom_metadata":{"hsts_enabled":"true","custom_maxage":value}
    id_check('hostname', hostname)
    raise("method must be one of #{VALID_METHODS}") unless VALID_METHODS.include?(method)
    raise("type must be one of #{VALID_TYPES}") unless VALID_TYPES.include?(type)

    data                   = {hostname: hostname, ssl: {method: method, type: type}}
    data[:custom_metadata] = custom_metadata unless custom_metadata.empty?

    cf_post(path: "/zones/#{zone_id}/custom_hostnames", data: data)
  end

  ##
  # list custom_hostnames
  def list(hostname: nil, id: nil, page: 1, per_page: 50, order: 'ssl', direction: 'desc', ssl: 0)
    raise 'cannot use both hostname and id' if hostname && id
    raise 'order must be ssl or ssl_status' unless VALID_ORDERS.include?(order)
    raise 'direction must be either asc or desc' unless VALID_DIRECTIONS.include?(direction)
    raise 'ssl must be either 0 or 1' unless ssl == 0 || ssl == 1

    params            = {page: page, per_page: per_page, order: order, direction: direction, ssl: ssl}
    params[:hostname] = hostname if hostname
    params[:id]       = id if id

    cf_get(path: "/zones/#{zone_id}/custom_hostnames", params: params)
  end

  ##
  # details of a custom hostname
  def show(id:)
    id_check('id', id)

    cf_get(path: "/zones/#{zone_id}/custom_hostnames/#{id}")
  end

  ##
  # update a custom hosntame
  def update(id:, method: nil, type: nil, custom_metadata: nil)
    id_check('id', id)

    data = {}

    unless type.nil? && method.nil?
      raise "method must be one of #{VALID_METHODS}" unless VALID_METHODS.include?(method)
      raise "type must be one of #{VALID_TYPES}" unless VALID_TYPES.include?(type)
      data[:ssl] = {method: method, type: type}
    end

    unless custom_metadata.nil?
      raise 'custom_metadata must be an object' unless custom_metadata.is_a?(Hash)
      data[:custom_metadata] = custom_metadata
    end

    cf_patch(path: "/zones/#{zone_id}/custom_hostnames/#{id}", data: data)
  end

  ##
  # delete a custom hostname and ssl certs
  def delete(id:)
    id_check('id', id)

    cf_delete(path: "/zones/#{zone_id}/custom_hostnames/#{id}")
  end
end
