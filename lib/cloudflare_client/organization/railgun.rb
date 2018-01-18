class CloudflareClient::Organization::Railgun < CloudflareClient::Organization
  ##
  # org railgun

  ##
  # list railguns
  def create(name:)
    id_check('name', name)
    data = {name: name}
    cf_post(path: "/organizations/#{org_id}/railguns", data: data)
  end

  ##
  # list railguns
  def list(page: 1, per_page: 50, direction: 'desc')
    params = {}

    unless direction.nil?
      valid_value_check(:direction, direction, VALID_DIRECTIONS)
      params[:direction] = direction
    end

    unless page.nil?
      range_check(:page, page, 1)
      params[:page] = page
    end

    unless per_page.nil?
      range_check(:per_page, per_page, 5, 50)
      params[:per_page] = per_page
    end

    cf_get(path: "/organizations/#{org_id}/railguns", params: params)
  end

  ##
  # show railgun details
  def show(id:)
    id_check(:id, id)

    cf_get(path: "/organizations/#{org_id}/railguns/#{id}")
  end

  ##
  # get zones connected to a given railgun
  def zones(id:)
    id_check(:id, id)

    cf_get(path: "/organizations/#{org_id}/railguns/#{id}/zones")
  end

  ##
  # enable a railgun
  def enable(id:)
    update_enabled(id: id, enabled: true)
  end

  ##
  # disable a railgun
  def disable(id:)
    update_enabled(id: id, enabled: false)
  end

  ##
  # delete an org railgun
  def delete(id:)
    id_check(:id, id)

    cf_delete(path: "/organizations/#{org_id}/railguns/#{id}")
  end

  private

  def update_enabled(id:, enabled:)
    id_check(:id, id)

    cf_patch(path: "/organizations/#{org_id}/railguns/#{id}", data: {enabled: enabled})
  end
end
