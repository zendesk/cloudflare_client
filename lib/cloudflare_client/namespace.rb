class CloudflareClient::Namespace < CloudflareClient
  Dir[File.expand_path('../namespace/*.rb', __FILE__)].each {|f| require f}

  attr_reader :account_id

  def initialize(args)
    @account_id = args.delete(:account_id)
    id_check(:account_id, account_id)
    super
  end

end
