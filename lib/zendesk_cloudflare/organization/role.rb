require 'zendesk_cloudflare/organization'

class CloudflareClient::Organization::Role < CloudflareClient::Organization
  ##
  # org roles
  #

  ##
  # list all organization roles
  def list
    cf_get(path: "/organizations/#{org_id}/roles")
  end

  ##
  # get details of an organization role
  def show(id:)
    id_check(:id, id)

    cf_get(path: "/organizations/#{org_id}/roles/#{id}")
  end
end
