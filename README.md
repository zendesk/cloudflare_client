# cloudflare_client
A simple Ruby API Client for Cloudflare's V4 API.

### Installation
Add the following line to your application's Gemfile, and then bundle.

```ruby
gem 'cloudflare_client_rb'
```

### Usage
Basic examples:

```ruby
# List zones - https://api.cloudflare.com/#zone-list-zones
zone_client = CloudflareClient::Zone.new(auth_key: auth_key, email: email)
pp zone_client.zones

# Example result:
{
  :success     => true,
  :errors      => [],
  :messages    => [],
  :result      => [
    {
      :id                    => "7c08916973d5469b865841b6ebf682ff",
      :name                  => "bode.biz",
      :development_mode      => 7200,
      :original_name_servers => ["ns1.originaldnshost.com", "ns2.originaldnshost.com"],
      :original_registrar    => "Mante Group",
      :original_dnshost      => "Metz-DuBuque",
      :created_on            => "2017-08-14T20:49:06.51188Z",
      :modified_on           => "2017-08-14T20:49:06.51190Z",
      :name_servers          => ["macgyver.co", "stehr.net", "upton.net"],
      :owner                 => {
        :id         => "c8e006bf340440559be1cec95a4ccb7b",
        :email      => "caie_haag@weber.co",
        :owner_type => "user"
      },
      :permissions           => ["#zone:read", "#zone:edit"],
      :plan                  => {
        :id            => "e7ad2d1ae39946ed91b7336f91ee32e6",
        :name          => "Pro Plan",
        :price         => 5.01,
        :currency      => "USD",
        :frequency     => "monthly",
        :legacy_id     => "pro",
        :is_subscribed => true,
        :can_subscribe => true
      },
      :plan_pending          => {
        :id            => "a223c15510c449ab9e8ea4b7c819b563",
        :name          => "Pro Plan",
        :price         => 82.23,
        :currency      => "USD",
        :frequency     => "monthly",
        :legacy_id     => "pro",
        :is_subscribed => true,
        :can_subscribe => true
      },
      :status                => "active",
      :paused                => false,
      :type                  => "full",
      :checked_on            => "2017-08-14T20:49:06.51339Z"
    }
  ],
  :result_info =>
    {
      :page        => 1,
      :per_page    => 20,
      :count       => 1,
      :total_count => 1
    }
}


# Create railgun - https://api.cloudflare.com/#railgun-create-railgun
railgun_client = CloudflareClient::Railgun.new(auth_key: auth_key, email: email)
pp railgun_client.create(name: 'My Railgun')

# Example result:
{
  :success  => true,
  :errors   => [],
  :messages => [],
  :result   => {
    :id              => "fc1ab93687af41a4aa25115083de0a04",
    :name            => "My Railgun",
    :status          => "active",
    :enabled         => true,
    :zones_connected => 2,
    :build           => "b1234",
    :version         => "2.1",
    :revision        => "123",
    :activation_key  => "875c8d82e8eb4af6aa06496ac9f4cb76",
    :activated_on    => "2017-08-15T18:35:29Z",
    :created_on      => "2017-08-15T18:35:29Z",
    :modified_on     => "2017-08-15T18:35:29Z"
  }
}
```

Please refer to the spec folder of this project to see usage examples for other classes.

### Contributing
Improvements are always welcome. Please follow these steps to contribute

1. Run `bundle` and then `rspec` to ensure all tests are passing
1. Submit a Pull Request with a detailed explanation of changes
1. Receive a :+1: from @zendesk/stanchion
1. The Stanchion team will merge your changes

### License
Use of this software is subject to important terms and conditions as set forth in the [LICENSE](LICENSE) file
