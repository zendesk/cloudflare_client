require_relative '../zendesk_cloudflare.rb'

class CloudflareClient::Railgun < CloudflareClient
  ##
  # Railgun methods
  def initialize(*args)
    super
  end

  ##
  # create(name: 'name of railgun')
  def create(name:)
    raise 'Railgun name cannot be nil' if name.nil?
    data = {name: name}
    cf_post(path: '/railguns', data: data)
  end

  ##
  # Get all the railguns
  def list(page: 1, per_page: 50, direction: 'desc')
    raise 'direction must be either desc | asc' unless direction == 'desc' || direction == 'asc'
    params = {page: page, per_page: per_page, direction: direction}
    cf_get(path: '/railguns', params: params)
  end

  ##
  # Get a single railgun
  def show(id:)
    raise 'must provide the id of the railgun' if id.nil?
    cf_get(path: "/railguns/#{id}")
  end

  ##
  # Get CF zones associated with a railgun
  def zones(id:)
    raise 'must provide the id of the railgun' if id.nil?
    cf_get(path: "/railguns/#{id}/zones")
  end

  ##
  # Enable a railgun
  def enable(id:)
    update_enabled(id: id, enabled: true)
  end

  ##
  # Disable a railgun
  def disable(id:)
    update_enabled(id: id, enabled: false)
  end

  ##
  # delete a railgun
  def delete(id:)
    raise 'must provide the id of the railgun' if id.nil?
    cf_delete(path: "/railguns/#{id}")
  end

  private

  def update_enabled(id:, enabled:)
    raise 'must provide the id of the railgun' if id.nil?
    cf_patch(path: "/railguns/#{id}", data: {enabled: enabled})
  end
end
