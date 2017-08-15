class CloudflareClient::Zone::Firewall < CloudflareClient::Zone::Base
  Dir[File.expand_path('../firewall/*.rb', __FILE__)].each {|f| require f}
end
