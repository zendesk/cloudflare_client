class CloudflareClient::Organization::Member < CloudflareClient::Organization
  ##
  # org members

  ##
  # list org members
  def list
    cf_get(path: "/organizations/#{org_id}/members")
  end

  ##
  # org member details
  def show(id:)
    id_check(:id, id)

    cf_get(path: "/organizations/#{org_id}/members/#{id}")
  end

  ##
  # update org member roles
  def update(id:, roles:)
    id_check(:id, id)
    non_empty_array_check(:roles, roles)

    data = {roles: roles}

    cf_patch(path: "/organizations/#{org_id}/members/#{id}", data: data)
  end

  ##
  # remove org member
  def delete(id:)
    id_check(:id, id)

    cf_delete(path: "/organizations/#{org_id}/members/#{id}")
  end
end
