class CloudflareClient::Zone::Base < CloudflareClient::Zone
  attr_reader :zone_id

  def initialize(args)
    @zone_id = args.delete(:zone_id)
    id_check('zone_id', zone_id)
    super(**args)
  end
end
