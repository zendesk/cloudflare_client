require 'zendesk_cloudflare/zone/base'

class CloudflareClient::Zone::CustomPage < CloudflareClient::Zone::Base
  ##
  # Custom pages for a zone
  ##
  # custom_pages list all avaialble custom_pages
  def list
    cf_get(path: "/zones/#{zone_id}/custom_pages")
  end

  ##
  # custom_page details
  def show(id:)
    raise 'id must not be nil' if id.nil?
    cf_get(path: "/zones/#{zone_id}/custom_pages/#{id}")
  end

  ##
  # update_custom_page
  def update(id:, url:, state:)
    id_check('id', id)
    id_check('url', url)
    raise 'state must be either default | customized' unless %w[default customized].include?(state)

    data = {url: url, state: state}

    cf_put(path: "/zones/#{zone_id}/custom_pages/#{id}", data: data)
  end
end
