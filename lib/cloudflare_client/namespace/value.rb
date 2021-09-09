class CloudflareClient::Value < CloudflareClient::Namespace
  attr_reader :namespace_id

  def initialize(args)
    @namespace_id = args.delete(:namespace_id)
    id_check(:namespace_id, namespace_id)
    super
  end

  def write(key:, value:, expiration_ttl: nil, metadata: nil)
    if expiration_ttl
      raise RuntimeError, 'expiration_ttl must be an integer' unless expiration_ttl.kind_of?(Integer)
    end

    data = metadata ? { value: value, metadata: metadata} : value
    cf_put(path: "/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}", data: data, params: {expiration_ttl: expiration_ttl})
  end

  def read(key:)
    cf_get(path: "/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}", raw: true)
  end

  def delete(key:)
    cf_delete(path: "/accounts/#{account_id}/storage/kv/namespaces/#{namespace_id}/values/#{key}")
  end
end
