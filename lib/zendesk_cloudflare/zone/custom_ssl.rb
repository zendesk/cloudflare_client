require 'zendesk_cloudflare/zone/base'

class CloudflareClient::Zone::CustomSSL < CloudflareClient::Zone::Base
  VALID_ORDERS = %w[status issuer priority expires_on].freeze

  ##
  # Custom SSL for a zone

  ##
  # create custom ssl for a zone
  def create(certificate:, private_key:, bundle_method: nil)
    id_check('certificate', certificate)
    id_check('private_key', private_key)
    bundle_method_check(bundle_method) unless bundle_method.nil?
    # TODO: validate the cert/key using openssl?  Could be difficult if they are
    # privately generated
    data = {certificate: certificate, private_key: private_key}
    data[:bundle_method] = bundle_method unless bundle_method.nil?
    cf_post(path: "/zones/#{zone_id}/custom_certificates", data: data)
  end

  ##
  # list custom ssl configurations
  def list(page: 1, per_page: 50, order: 'priority', direction: 'asc', match: 'all')
    raise ("order must be one of #{VALID_ORDERS}") unless VALID_ORDERS.include?(order)
    raise ('direction must be asc || desc') unless (direction == 'asc' || direction == 'desc')
    raise ('match must be all || any') unless (match == 'any' || match == 'all')
    params = {page: page, per_page: per_page}
    params[:match] = match
    params[:direction] = direction
    cf_get(path: "/zones/#{zone_id}/custom_certficates", params: params)
  end

  ##
  # details of a single config
  def show(configuration_id:)
    raise 'ssl configuration id required' if configuration_id.nil?
    cf_get(path: "/zones/#{zone_id}/custom_certificates/#{configuration_id}")
  end

  ##
  # updates a custom ssl record
  def update(id:, private_key: nil, certificate: nil, bundle_method: nil)
    id_check('id', id)
    id_check('private_key must be provided') if private_key.nil?
    bundle_method_check(bundle_method)
    data = {private_key: private_key, certificate: certificate, bundle_method: bundle_method}
    cf_patch(path: "/zones/#{zone_id}/custom_certificates/#{id}", data: data)
  end

  ##
  # re-prioritize ssl certs data = [{id: "cert_id", priority: 2}, {id: "cert_id", priority: 1}]
  def prioritize(data: [])
    raise 'must provide an array of certifiates and priorities' unless data.is_a?(Array) && !data.empty?
    cf_put(path: "/zones/#{zone_id}/custom_certificates/prioritize", data: data)
  end

  ##
  # delete a custom ssl cert
  def delete(id:)
    id_check('id', id)
    cf_delete(path: "/zones/#{zone_id}/custom_certificates/#{id}")
  end
end
