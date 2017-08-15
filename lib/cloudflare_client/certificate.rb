class CloudflareClient::Certificate < CloudflareClient
  VALID_REQUESTED_VALIDITIES = [7, 30, 90, 365, 730, 1095, 5475].freeze
  VALID_REQUEST_TYPES        = %w[origin-rsa origin-ecc keyless-certificate].freeze

  ##
  # cloudflare CA

  ##
  # list certificates
  def list(zone_id: nil)
    cf_get(path: '/certificates', params: {zone_id: zone_id})
  end

  ##
  # create a certificate
  def create(hostnames:, requested_validity: 5475, request_type: 'origin-rsa', csr: nil)
    non_empty_array_check(:hostnames, hostnames)
    valid_value_check(:requested_validity, requested_validity, VALID_REQUESTED_VALIDITIES)
    valid_value_check(:request_type, request_type, VALID_REQUEST_TYPES)

    data       = {hostnames: hostnames, requested_validity: requested_validity, request_type: request_type}
    data[:csr] = csr unless csr.nil?

    cf_post(path: '/certificates', data: data)
  end

  ##
  # details of a certificate
  def show(id:)
    id_check(:id, id)
    cf_get(path: "/certificates/#{id}")
  end

  ##
  # revoke a cert
  def revoke(id:)
    id_check(:id, id)
    cf_delete(path: "/certificates/#{id}")
  end
end
