class CloudflareClient::Zone::Subscription < CloudflareClient::Zone::Base
  VALID_FREQUENCIES = %w[weekly monthly quarterly yearly].freeze
  VALID_STATES      = %w[Trial Provisioned Paid AwaitingPayment Cancelled Failed Expired].freeze

  ##
  #zone_subscription

  ##
  # get a zone subscription
  # FIXME: seems to throw a 404
  def show
    cf_get(path: "/zones/#{zone_id}/subscription")
  end

  ##
  # create a zone subscriptions
  # FIXME: api talks about lots of read only constrains
  def create(price:, currency:, id:, frequency:, component_values: nil, rate_plan: nil, zone: nil, state: nil)
    basic_type_check(:price, price, Numeric)
    basic_type_check(:currency, currency, String)
    basic_type_check(:id, id, String)
    max_length_check(:id, id)
    valid_value_check(:frequency, frequency, VALID_FREQUENCIES)

    data = {price: price, currency: currency, id: id, frequency: frequency}

    unless component_values.nil?
      non_empty_array_check(:component_values, component_values)
      data[:component_values] = component_values
    end

    unless rate_plan.nil?
      non_empty_hash_check(:rate_plan, rate_plan)
      data[:rate_plan] = rate_plan
    end

    unless zone.nil?
      non_empty_hash_check(:zone, zone)
      data[:zone] = zone
    end

    unless state.nil?
      valid_value_check(:state, state, VALID_STATES)
      data[:state] = state
    end

    cf_post(path: "/zones/#{zone_id}/subscription", data: data)
  end

  ##
  # FIXME: more read-only questions abound
  # update a zone subscription
  # def update
  # end
end
