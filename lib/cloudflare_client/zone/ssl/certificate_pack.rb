class CloudflareClient::Zone::SSL::CertificatePack < CloudflareClient::Zone::SSL
  ##
  # certificate_packs

  ##
  # list all certificate packs
  def list
    cf_get(path: "/zones/#{zone_id}/ssl/certificate_packs")
  end

  ##
  # re-order certificate packs
  def order(hosts: nil)
    non_empty_array_check(:hosts, hosts) unless hosts.nil?

    data = {hosts: hosts}

    # TODO: test against api
    cf_post(path: "/zones/#{zone_id}/ssl/certificate_packs", data: data)
  end

  ##
  # edit a certificate pack
  def update(id:, hosts:)
    id_check(:id, id)
    non_empty_array_check(:hosts, hosts) unless hosts.nil?

    data = {hosts: hosts}

    cf_patch(path: "/zones/#{zone_id}/ssl/certificate_packs/#{id}", data: data)
  end
end
