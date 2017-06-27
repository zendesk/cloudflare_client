require 'zendesk_cloudflare'

class CloudflareClient::Organization < CloudflareClient
  attr_reader :org_id

  ##
  # Organization based operations
  def initialize(args)
    @org_id = args.delete(:org_id)
    id_check(:org_id, org_id)
    super
  end

  ##
  # get an org's details
  def show
    cf_get(path: "/organizations/#{org_id}")
  end

  ##
  # update a given org (only supports name)
  def update(name: nil)
    data = name.nil? ? {} : {name: name}
    cf_patch(path: "/organizations/#{org_id}", data: data)
  end
end
