class CloudflareClient::Zone::SSL < CloudflareClient::Zone::Base
  Dir[File.expand_path('../ssl/*.rb', __FILE__)].each {|f| require f}

  VALID_RETRY_VERIFICATIONS = [true].freeze

  ##
  # analyze a certificate
  def analyze(certificate: nil, bundle_method: 'ubiquitous')
    data               = {}
    data[:certificate] = certificate unless certificate.nil?

    bundle_method_check(bundle_method)
    data[:bundle_method] = bundle_method

    cf_post(path: "/zones/#{zone_id}/ssl/analyze", data: data)
  end

  ##
  # get ssl verification
  def verification(retry_verification: nil)
    unless retry_verification.nil?
      valid_value_check(:retry_verification, retry_verification, VALID_RETRY_VERIFICATIONS)
      params = {retry: true}
    end

    cf_get(path: "/zones/#{zone_id}/ssl/verification", params: params)
  end
end
