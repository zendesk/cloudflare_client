require 'zendesk_cloudflare/zone/base'

class CloudflareClient::Zone::KeylessSSL < CloudflareClient::Zone::Base
  ##
  # keyless_ssl

  ##
  # create a keyless ssl config
  def create(host:, port:, certificate:, name: nil, bundle_method: 'ubiquitous')
    raise 'host required' if host.nil?
    raise 'certificate required' if certificate.nil?
    bundle_method_check(bundle_method)

    data        = {host: host, port: port, certificate: certificate, bundle_method: bundle_method}
    data[:name] = name ? name : "#{host} Keyless SSL"

    cf_post(path: "/zones/#{zone_id}/keyless_certificates", data: data)
  end

  ##
  # list all the keyless ssl configs
  def list
    cf_get(path: "/zones/#{zone_id}/keyless_certificates")
  end

  ##
  # details of a keyless_ssl_config
  def show(id:)
    id_check('id', id)

    cf_get(path: "/zones/#{zone_id}/keyless_certificates/#{id}")
  end

  ##
  # updates a keyless ssl config
  def update(id:, host: nil, name: nil, port: nil, enabled: nil)
    id_check('id', id)
    unless enabled.nil?
      raise 'enabled must be true||false' unless enabled == true || enabled == false
    end

    data           = {}
    data[:host]    = host unless host.nil?
    data[:name]    = name ? name : "#{host} Keyless SSL"
    data[:port]    = port unless port.nil?
    data[:enabled] = enabled unless enabled.nil?

    cf_patch(path: "/zones/#{zone_id}/keyless_certificates/#{id}", data: data)
  end

  ##
  # delete a custom_ssl_config
  def delete(id:)
    id_check('id', id)

    cf_delete(path: "/zones/#{zone_id}/keyless_certificates/#{id}")
  end
end
