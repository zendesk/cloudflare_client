# https://api.cloudflare.com/#custom-hostname-for-a-zone-list-custom-hostnames
class CloudflareClient::Zone::CustomHostname < CloudflareClient::Zone::Base
  VALID_METHODS = %w[http email cname].freeze
  VALID_TYPES   = ['read only', 'dv'].freeze
  VALID_ORDERS  = %w[ssl ssl_status].freeze
  DEFAULT_SSL_PROPERTIES = { method: 'http', type: 'dv' }.freeze

  ##
  # create custom_hostname
  # - :custom_metadata may only work for enterprise or better customers
  # - :ssl has undocumented properties: 'custom_certificate' and 'custom_key', or can be nulled
  def create(hostname:, ssl: DEFAULT_SSL_PROPERTIES, custom_metadata: {}, custom_origin_server: nil)
    #FIXME: implement checks for the custom_metedata/find out of it's going to be exposed to anyone else
    #"custom_metadata":{"hsts_enabled":"true"}
    #"custom_metadata":{"hsts_enabled":"true","custom_maxage":value}
    id_check('hostname', hostname)

    if ssl && ssl[:method] && ssl[:type]
      valid_value_check(:method, ssl[:method], VALID_METHODS)
      valid_value_check(:type,   ssl[:type],   VALID_TYPES)
    end

    data                   = { hostname: hostname, ssl: ssl }
    data[:custom_origin_server] = custom_origin_server unless custom_origin_server.nil?
    data[:custom_metadata] = custom_metadata unless custom_metadata.empty?

    cf_post(path: "/zones/#{zone_id}/custom_hostnames", data: data)
  end

  ##
  # list custom_hostnames
  def list(hostname: nil, id: nil, page: 1, per_page: 50, order: 'ssl', direction: 'desc', ssl: 0, ssl_status: nil)
    raise 'cannot use both hostname and id' if hostname && id
    valid_value_check(:order, order, VALID_ORDERS)
    valid_value_check(:direction, direction, VALID_DIRECTIONS)
    valid_value_check(:ssl, ssl, [0, 1])

    params              = {page: page, per_page: per_page, order: order, direction: direction, ssl: ssl}
    params[:ssl_status] = ssl_status if ssl_status
    params[:hostname]   = hostname if hostname
    params[:id]         = id if id

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
  # https://api.cloudflare.com/#custom-hostname-for-a-zone-update-custom-hostname-configuration
  def update(id:, ssl: {}, custom_metadata: nil, custom_origin_server: nil)
    id_check('id', id)

    data = {}

    if ssl && ssl[:method] && ssl[:type]
      valid_value_check(:method, ssl[:method], VALID_METHODS)
      valid_value_check(:type,   ssl[:type],   VALID_TYPES)
    end

    # Setting this to "null" requests removal of the attached certificate. We're
    # using {} as the default value to denote "don't alter the SSL".
    data[:ssl] = ssl unless ssl == {}

    unless custom_metadata.nil?
      raise 'custom_metadata must be an object' unless custom_metadata.is_a?(Hash)
      data[:custom_metadata] = custom_metadata
    end

    unless custom_origin_server.nil?
      data[:custom_origin_server] = custom_origin_server
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
