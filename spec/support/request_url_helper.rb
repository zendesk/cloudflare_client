module RequestUrlHelper
  extend RSpec::SharedContext

  let(:base_url) { 'https://api.cloudflare.com/client/v4' }
  let(:request_url) do
    url              = Addressable::URI.parse("#{base_url}#{request_path}")
    url.query_values = request_query if defined?(request_query)
    url.to_s
  end
end

RSpec.configure { |c| c.include RequestUrlHelper }
