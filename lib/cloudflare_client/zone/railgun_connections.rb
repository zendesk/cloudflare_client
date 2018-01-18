class CloudflareClient::Zone::RailgunConnections < CloudflareClient::Zone::Base
  ##
  # Railgun connections

  ##
  # available railguns
  def list
    cf_get(path: "/zones/#{zone_id}/railguns")
  end

  ##
  # details of a single railgun
  def show(id:)
    raise 'railgun id required' if id.nil?
    cf_get(path: "/zones/#{zone_id}/railguns/#{id}")
  end

  ##
  # test a railgun connection
  def test(id:)
    raise 'railgun id required' if id.nil?
    cf_get(path: "/zones/#{zone_id}/railguns/#{id}/diagnose")
  end

  ##
  # connect a railgun
  def connect(id:)
    update_connection(id: id, connected: true)
  end

  ##
  # disconnect a railgun
  def disconnect(id:)
    update_connection(id: id, connected: false)
  end

  private

  def update_connection(id:, connected:)
    raise 'railgun id required' if id.nil?
    cf_patch(path: "/zones/#{zone_id}/railguns/#{id}", data: {connected: connected})
  end
end
