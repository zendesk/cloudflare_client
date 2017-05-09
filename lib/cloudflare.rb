require 'json'
module Cloudflare


  API_BASE    = "https://api.cloudflare.com/client/v4/".freeze
  ORG_ID      = "7f86e0ad68da283973e812b9d6ecf24d".freeze #Fixme: also variable

  class Zone
    BASE_URI = "zones/"
    def initialize(params = {})
      params[:base_uri] = params[:zone_id].nil? ? BASE_URI : BASE_URI + params[:zone_id]
      @cf_client = Cloudflare::CfClient.new(params)
    end

    # TODO: deal with pagination
    def list(params = {})
      @cf_client.get(params)

    end

    def create(args = {})
      raise ("zone name required") if args[:name].nil?
      args = args["organization"] = {"id": ORG_ID, "name": args[:name], "jump_start": false,  "status": "active", "permisssions": ["#zones:read"]}
      @cf_client.post
    end

    # either create/update or get a single one
    def custom_hostnames(custom_hostname = nil)
      # if there's an id, get the object back from the api, see if
      # it needs to be updated
      if custom_hostname.nil?
        return @cf_client.get(url: "/custom_hostnames")
      elsif custom_hostname[:id]
        ch = @cf_client.get(url: "/custom_hostnames/#{custom_hostname[:id]}")
      end
      if ch.dig(:result, :ssl)[:status] != "ctive" && (custom_hostname[:ssl_method] != ch.dig(:result, :ssl)[:method])
        puts "update dis shit"
      end
    end

    def update_custom_hostname(custom_hostname = nil)
    end

    def delete_custom_hostname(id: nil)
    end
  end

  class Organization
    BASE_URI = ""
  end

  class CloudflareIps
    BASE_URI = ""
  end

  class User
    BASE_URI = ""
  end

  class CfClient

    require 'faraday'
    require 'byebug' #Fixme

    def initialize(base_uri)
      @connection ||= build_client(base_uri)
    end

    def build_client(params)
      full_uri = Cloudflare::API_BASE + params[:base_uri]
      client = Faraday.new(:url => full_uri)
      client.headers["X-Auth-Key"] = params[:auth_key]
      client.headers["X-Auth-Email"] = params[:email]
      client.headers["Content-Type"] =  "application/json"
      client
    end

    def post(payload)
      response = @connection.post { |request| request.body = payload }
      raise ("api returned #{response.body}") unless response.status == 200
      JSON.parse(response.body)
    end

    # bad params dont' seem to bother the api, but may wana validate
    def get(params: {}, url: nil)
      params.merge({per_page: 50})
      response = @connection.get do |req|
        req.params = params
        req.url(@connection.url_prefix.path += url) unless url.nil?
      end
      raise ("api returned #{response.body}") unless response.status == 200
      JSON.parse(response.body, symbolize_names: true)
    end

    def patch
    end

    def delete
    end
  end
end
