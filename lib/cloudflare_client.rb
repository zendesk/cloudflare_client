##
# General class for the client
class CloudflareClient
  require 'json'
  require 'faraday'
  require 'date'
  require 'byebug'
  Dir[File.expand_path('../cloudflare_client/*.rb', __FILE__)].each { |f| require f }
  require 'cloudflare_client/middleware/response/raise_error'

  API_BASE             = 'https://api.cloudflare.com/client/v4'.freeze
  VALID_BUNDLE_METHODS = %w[ubiquitous optimal force].freeze
  VALID_DIRECTIONS     = %w[asc desc].freeze
  VALID_MATCHES        = %w[any all].freeze

  POSSIBLE_API_SETTINGS = %w[
    advanced_ddos
    always_online
    automatic_https_rewrites
    browser_cache_ttl
    browser_check
    cache_level
    challenge_ttl
    development_mode
    email_obfuscation
    hotlink_protection
    ip_geolocation
    ipv6
    minify
    mobile_redirect
    mirage
    origin_error_page_pass_thru
    opportunistic_encryption
    polish
    webp
    prefetch_preload
    response_buffering
    rocket_loader
    security_header
    security_level
    server_side_exclude
    sort_query_string_for_cache
    ssl
    tls_1_2_only
    tls_1_3
    tls_client_auth
    true_client_ip_header
    waf
    http2
    pseudo_ipv4
    websockets
  ].freeze

  def initialize(auth_key: nil, email: nil, auth_token: nil, &block)
    raise('Missing auth_key or auth_token') if auth_key.nil? && auth_token.nil?
    raise('missing email') if email.nil? && !auth_key.nil?
    @cf_client ||= build_client(auth_key: auth_key, email: email, auth_token: auth_token, &block)
  end

  #TODO: add the time based stuff

  #TODO: cloudflare IPs
  #TODO: AML
  #TODO: load balancer monitors
  #TODO: load balancer pools
  #TODO: org load balancer monitors
  #TODO: org load balancer pools
  #TODO: load balancers

  private

  def bundle_method_check(bundle_method)
    unless VALID_BUNDLE_METHODS.include?(bundle_method)
      raise("valid bundle methods are #{VALID_BUNDLE_METHODS.flatten}")
    end
  end

  def date_rfc3339?(ts)
    begin
      DateTime.rfc3339(ts)
    rescue ArgumentError
      return false
    end
    true
  end

  def iso8601_check(name, ts)
    DateTime.iso8601(ts)
  rescue ArgumentError
    raise "#{name} must be a valid iso8601 timestamp"
  end

  def timestamp_check(name, ts)
    Time.at(ts).to_datetime
  rescue TypeError
    raise "#{name} must be a valid unix timestamp"
  end

  def id_check(name, id)
    raise "#{name} required" if id.nil?
  end

  def valid_value_check(name, value, valid_values)
    raise "#{name} must be one of #{valid_values}" unless valid_values.include?(value)
  end

  def non_empty_array_check(name, array)
    raise "#{name} must be an array of #{name}" unless array.is_a?(Array) && !array.empty?
  end

  def non_empty_hash_check(name, hash)
    raise "#{name} must be an hash of #{name}" unless hash.is_a?(Hash) && !hash.empty?
  end

  def basic_type_check(name, value, type)
    raise "#{name} must be a #{type}" unless value.is_a?(type)
  end

  def max_length_check(name, value, max_length=32)
    raise "the length of #{name} must not exceed #{max_length}" unless value.length <= max_length
  end

  def range_check(name, value, min=nil, max=nil)
    if min && max
      raise "#{name} must be between #{min} and #{max}" unless value >= min && value <= max
    elsif min
      raise "#{name} must be equal or larger than #{min}" unless value >= min
    elsif max
      raise "#{name} must be equal or less than #{max}" unless value <= max
    end
  end

  def build_client(params)
    # we need multipart form encoding for some of these operations
    client                                      = Faraday.new(url: API_BASE) do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.use Middleware::Response::RaiseError
    end

    client.headers['Content-Type']              = 'application/json'
    if params[:auth_token]
      client.headers['Authorization'] = "Bearer #{params[:auth_token]}"
    else
      client.headers['X-Auth-Key']                = params[:auth_key]
      client.headers['X-Auth-User-Service-Key	']  = params[:auth_key] #FIXME, is this always the same?
      client.headers['X-Auth-Email']              = params[:email]
    end

    yield client if block_given?
    client.adapter :net_http
    client
  end

  def cf_post(path: nil, data: {})
    raise('No data to post') if data.empty?
    result = @cf_client.post do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json
    end
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_get(path: nil, params: {}, raw: nil, extra_headers: {})
    result = @cf_client.get do |request|
      request.headers.merge!(extra_headers) unless extra_headers.empty?
      request.url(API_BASE + path) unless path.nil?
      unless params.nil?
        request.params = params if params.values.any? { |i| !i.nil? }
      end
    end
    unless raw.nil?
      return result.body
    end
    # we ask for compressed logs.  uncompress if we get them
    # as the user can always ask for raw stuff
    if result.headers["content-encoding"] == 'gzip'
      return Zlib::GzipReader.new(StringIO.new(result.body.to_s)).read
    end
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_put(path: nil, data: nil, params: nil)
    result = @cf_client.put do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.nil?
      unless params.nil?
        request.params = params if params.values.any? { |i| !i.nil? }
      end
    end
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_patch(path: nil, data: {})
    result               = @cf_client.patch do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.empty?
    end
    JSON.parse(result.body, symbolize_names: true)
  end

  def cf_delete(path: nil, data: {})
    result = @cf_client.delete do |request|
      request.url(API_BASE + path) unless path.nil?
      request.body = data.to_json unless data.empty?
    end
    JSON.parse(result.body, symbolize_names: true)
  end

  def valid_setting?(name = nil)
    return false if name.nil?
    return false unless POSSIBLE_API_SETTINGS.include?(name)
    true
  end
end