class CloudflareClient::Zone::Firewall::WAFPackage::Base < CloudflareClient::Zone::Firewall::WAFPackage
  attr_reader :package_id

  def initialize(args)
    @package_id = args.delete(:package_id)
    id_check('package_id', package_id)
    super
  end
end
