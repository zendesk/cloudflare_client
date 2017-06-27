FactoryGirl.define do
  factory :subscriptions, class: Hash do
    skip_create
    initialize_with(&FactoryHelper.initializer)

    factory :subscription_show do
      success true
      errors []
      messages []
      result { create(:subscription_result) }
    end

    factory :subscription_result do
      transient { component_value_count { rand(1..3) } }
      id { SecureRandom.uuid.gsub('-', '') }
      state 'Paid'
      price 20
      currency 'USD'
      component_values { create_list(:subscription_component_value, component_value_count) }
      zone { create(:subscription_zone) }
      frequency 'monthly'
      rate_plan { create(:subscription_rate_plan) }
      current_period_end { Time.now.utc.advance(years: -1).iso8601 }
      current_period_start { Time.now.utc.advance(months: -8).iso8601 }
    end

    factory :subscription_component_value do
      name 'page_rules'
      value 20
      default 5
      price 5
    end

    factory :subscription_zone do
      id { SecureRandom.uuid.gsub('-', '') }
      name { Faker::Internet.domain_name }
    end

    factory :subscription_rate_plan do
      id 'free'
      public_name 'Business Plan'
      currency 'USD'
      scope 'zone'
      externally_managed { Faker::Boolean.boolean }
    end
  end
end
