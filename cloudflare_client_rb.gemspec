require_relative 'lib/cloudflare_client/version'

name = 'cloudflare_client_rb'

Gem::Specification.new name, CloudflareClient::VERSION do |s|
  s.summary = 'lightweight cloudflare api client'
  s.authors = ['ian waters']
  s.email = 'iwaters@zendesk.com'
  s.homepage = "https://github.com/zendesk/#{name}"
  s.files = Dir['lib/**/*.rb']
  s.license = 'Apache-2.0'
  s.required_ruby_version = '>= 2.3.0'
end
