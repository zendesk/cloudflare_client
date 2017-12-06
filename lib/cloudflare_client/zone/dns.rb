class CloudflareClient::Zone::DNS < CloudflareClient::Zone::Base
  VALID_TYPES = ['A', 'AAAA', 'CNAME', 'TXT', 'SRV', 'LOC', 'MX', 'NS', 'SPF', 'read only'].freeze

  ##
  # DNS methods

  ##
  # Create a dns record
  def create(name:, type:, content:, ttl: nil, proxied: nil)
    raise ("type must be one of #{VALID_TYPES.flatten}") unless VALID_TYPES.include?(type)
    data = {name: name, type: type, content: content}
    data[:ttl] = ttl unless ttl.nil?
    data[:proxied] = proxied unless proxied.nil?
    cf_post(path: "/zones/#{zone_id}/dns_records", data: data)
  end

  ##
  # list/search for dns records in a given zone
  def list(name: nil, content: nil, per_page: 50, page_no: 1, order: 'type', match: 'all', type: nil)
    raise('match must be either all | any') unless %w[all any].include?(match)
    params           = {per_page: per_page, page: page_no, order: order}
    params[:name]    = name unless name.nil?
    params[:content] = content unless content.nil?
    params[:type]    = type unless type.nil?
    cf_get(path: "/zones/#{zone_id}/dns_records", params: params)
  end

  ##
  # details for a given dns_record
  def show(id:)
    id_check('dns record id', id)
    cf_get(path: "/zones/#{zone_id}/dns_records/#{id}")
  end

  ##
  # update a dns record.
  # zone_id, id, type, and name are all required.  ttl and proxied are optional
  def update(id:, type:, name:, content:, ttl: nil, proxied: nil)
    id_check('dns record id', id)
    id_check('dns record type', type)
    id_check('dns record name', name)
    id_check('dns record content', content)
    raise('must suply type, name, and content') if (type.nil? || name.nil? || content.nil?)
    data           = {type: type, name: name, content: content}
    data[:ttl]     = ttl unless ttl.nil?
    data[:proxied] = proxied unless proxied.nil?
    cf_put(path: "/zones/#{zone_id}/dns_records/#{id}", data: data)
  end

  ##
  # delete a dns record
  # id is required.  ttl and proxied are optional
  def delete(id:)
    id_check('id', id)
    cf_delete(path: "/zones/#{zone_id}/dns_records/#{id}")
  end

  ##
  # import a BIND formatted zone file
  #  def import_zone_file(path_to_file: nil)
  #    # FIXME: not tested
  #    raise("full path of file to import") if path_to_file.nil?
  #    # TODO: ensure that this is a bind file?
  #    raise("import file_name does not exist") if File.exists?(path_to_file)
  #    data = { file: Faraday::UploadIO.new(path_to_file, 'multipart/form-data') }
  #    cf_post(path: "/v4/zones/#{zone_id}/dns_records/import", data: data)
  #  end
end
