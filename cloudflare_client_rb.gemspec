name = 'cloudflare_client_rb'

Gem::Specification.new name, '1.0.0' do |s|
  s.summary = 'lightweight cloudflare api client'
  s.authors = ['ian waters']
  s.email = 'iwaters@zendesk.com'
  s.homepage = "https://github.com/zendesk/#{name}"
  s.files = Dir['lib/**/*.rb']
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.3.0'
end
