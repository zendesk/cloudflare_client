require_relative 'custom_hostname'
#class CloudflareClient::Zone::CustomHostnameV2 < CloudflareClient::Zone::Base
class CloudflareClient::Zone::CustomHostnameV2 < CloudflareClient::Zone::CustomHostname

  def create(hostname:, ssl: DEFAULT_SSL_PROPERTIES, custom_metadata: {}, custom_origin_server: nil)
    super
  end

  def list(hostname: nil, id: nil, page: 1, per_page: 50, order: 'ssl', direction: 'desc', ssl: 0)
    super
  end

  def show(id:)
    super
  end

  def update(id:, ssl: {}, custom_metadata: nil, custom_origin_server: nil)
    super
  end

  def delete(id:)
    super
  end
end
