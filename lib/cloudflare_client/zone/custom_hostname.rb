class CloudflareClient::Zone::CustomHostname < CloudflareClient::Zone::Base
  VALID_METHODS = %w[http email cname].freeze
  VALID_TYPES   = ['read only', 'dv'].freeze
  VALID_ORDERS  = %w[ssl ssl_status].freeze

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
    valid_value_check(:method, method, VALID_METHODS)
    valid_value_check(:type, type, VALID_TYPES)

    data                   = {hostname: hostname, ssl: {method: method, type: type}}
    data[:custom_metadata] = custom_metadata unless custom_metadata.empty?

    cf_post(path: "/zones/#{zone_id}/custom_hostnames", data: data)
  end

  ##
  # list custom_hostnames
  def list(hostname: nil, id: nil, page: 1, per_page: 50, order: 'ssl', direction: 'desc', ssl: 0)
    raise 'cannot use both hostname and id' if hostname && id
    valid_value_check(:order, order, VALID_ORDERS)
    valid_value_check(:direction, direction, VALID_DIRECTIONS)
    valid_value_check(:ssl, ssl, [0, 1])

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
      valid_value_check(:method, method, VALID_METHODS)
      valid_value_check(:type, type, VALID_TYPES)

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
