class CloudflareClient
  class Zone < CloudflareClient
    require_relative './zone/base.rb'
    Dir[File.expand_path('../zone/*.rb', __FILE__)].each { |f| require f }

    VALID_ZONE_STATUSES = %w[active pending initializing moved deleted deactivated].freeze

    ##
    # Zone based operations
    def initialize(*args)
      super
    end

    ##
    # list_zones will either list all zones or search for zones based on params
    # results are paginated!
    # list_zones(name: name_of_zone, status: active|pending, page: page_no)
    def zones(name: nil, status: nil, per_page: 50, page: 1)
      params            = {}
      params[:per_page] = per_page
      params[:page]     = page
      params[:name]     = name unless name.nil?

      unless status.nil?
        raise "status must be one of #{VALID_ZONE_STATUSES.flatten}" unless VALID_ZONE_STATUSES.include?(status)
        params[:status] = status
      end

      cf_get(path: '/zones', params: params)
    end

    ##
    # create's a zone with a given name
    # create_zone(name: name_of_zone, jump_start: true|false (default true),
    # organization: {id: org_id, name: org_name})
    def create_zone(name:, jump_start: true, organization: {id: nil, name: nil})
      raise('Zone name required') if name.nil?
      unless organization[:id].nil? && organization[:name].nil
        org_data = organization.merge(status: 'active', permissions: ['#zones:read'])
      end
      data = {name: name, jump_start: jump_start, organization: org_data}
      cf_post(path: '/zones', data: data)
    end

    ##
    # request another zone activation (ssl) check
    # zone_activation_check(zone_id:)
    def zone_activation_check(zone_id:)
      raise('zone_id required') if zone_id.nil?
      cf_put(path: "/zones/#{zone_id}/activation_check")
    end

    ##
    # return all the details for a given zone_id
    # zone_details(zone_id: id_of_my_zone
    def zone(zone_id:)
      raise('zone_id required') if zone_id.nil?
      cf_get(path: "/zones/#{zone_id}")
    end

    ##
    # edit the properties of a zone
    # NOTE: some of these options require an enterprise account
    # edit_zone(zone_id: id_of_zone, paused: true|false,
    # vanity_name_servers: ['ns1.foo.bar', 'ns2.foo.bar'], plan: {id: plan_id})
    def edit_zone(zone_id:, paused: nil, vanity_name_servers: [], plan: {id: nil})
      raise('zone_id required') if zone_id.nil?
      data                       = {}
      data[:paused]              = paused unless paused.nil?
      data[:vanity_name_servers] = vanity_name_servers unless vanity_name_servers.empty?
      data[:plan]                = plan unless plan[:id].nil?
      cf_patch(path: "/zones/#{zone_id}", data: data)
    end

    ##
    # various zone caching controlls.
    # supploy an array of tags, or files, or the purge_everything bool
    def purge_zone_cache(zone_id:, tags: [], files: [], purge_everything: nil)
      raise('zone_id required') if zone_id.nil?
      if purge_everything.nil? && (tags.empty? && files.empty?)
        raise('specify a combination tags[], files[] or purge_everything')
      end
      data                    = {}
      data[:purge_everything] = purge_everything unless purge_everything.nil?
      data[:tags]             = tags unless tags.empty?
      data[:files]            = files unless files.empty?
      cf_delete(path: "/zones/#{zone_id}/purge_cache", data: data)
    end

    ##
    # delete a given zone
    # delete_zone(zone_id: id_of_zone
    def delete_zone(zone_id:)
      raise('zone_id required') if zone_id.nil?
      cf_delete(path: "/zones/#{zone_id}")
    end

    ##
    # return all settings for a given zone
    def zone_settings(zone_id:)
      raise('zone_id required') if zone_id.nil?
      cf_get(path: "/zones/#{zone_id}/settings")
    end

    ##
    # there are a lot of settings that can be returned.
    def zone_setting(zone_id:, name:)
      raise('zone_id required') if zone_id.nil?
      raise('setting_name not valid') if name.nil? || !valid_setting?(name)
      cf_get(path: "/zones/#{zone_id}/settings/#{name}")
    end

    ##
    # update 1 or more settings in a zone
    # settings: [{name: value: true},{name: 'value'}...]
    # https://api.cloudflare.com/#zone-settings-properties
    def update_zone_settings(zone_id:, settings: [])
      raise('zone_id required') if zone_id.nil?
      data = settings.map do |setting|
        raise("setting_name \"#{setting[:name]}\" not valid") unless valid_setting?(setting[:name])
        {id: setting[:name], value: setting[:value]}
      end
      data = {items: data}
      cf_patch(path: "/zones/#{zone_id}/settings", data: data)
    end

    #TODO: zone_rate_plans
  end
end
