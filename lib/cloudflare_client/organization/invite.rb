class CloudflareClient::Organization::Invite < CloudflareClient::Organization
  ##
  # org invites

  ##
  # create an org invite
  def create(email:, roles:, auto_accept: nil)
    basic_type_check(:email, email, String)
    max_length_check(:email, email, 90)
    non_empty_array_check(:roles, roles)

    data = {invited_member_email: email, roles: roles}

    unless auto_accept.nil?
      valid_value_check(:auto_accept, auto_accept, [true, false])
      data[:auto_accept] = auto_accept
    end

    cf_post(path: "/organizations/#{org_id}/invites", data: data)
  end

  ##
  # org invites
  def list
    cf_get(path: "/organizations/#{org_id}/invites")
  end

  ##
  # org invite details
  def show(id:)
    id_check(:id, id)

    cf_get(path: "/organizations/#{org_id}/invites/#{id}")
  end

  ##
  # update an organization invites roles
  def update(id:, roles:)
    id_check(:id, id)
    non_empty_array_check(:roles, roles)

    data = {roles: roles}

    cf_patch(path: "/organizations/#{org_id}/invites/#{id}", data: data)
  end

  ##
  # cancel an organization invite
  def delete(id:)
    id_check(:id, id)
    cf_delete(path: "/organizations/#{org_id}/invites/#{id}")
  end
end
