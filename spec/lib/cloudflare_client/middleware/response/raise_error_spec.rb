describe CloudflareClient::Middleware::Response::RaiseError do
  let(:service) { Faraday::Adapter::Test::Stubs.new }

  let(:connection) do
    Faraday.new(url: 'https://example.com') do |conn|
      conn.use described_class
      conn.adapter :test, service
    end
  end

  it "raises BadRequest on 400" do
    expect { response_status 400 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::BadRequest)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises Unauthorized on 401" do
    expect { response_status 401 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::Unauthorized)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises Forbidden on 403" do
    expect { response_status 403 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::Forbidden)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises ResourceNotFound on 404" do
    expect { response_status 404 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::ResourceNotFound)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises Faraday::ConnectionFailed on 407" do
    expect { response_status 407 }.to raise_error do |error|
      expect(error).to be_a(Faraday::ConnectionFailed)
    end
  end

  it "raises Conflict on 409" do
    expect { response_status 409 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::Conflict)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises Gone on 410" do
    expect { response_status 410 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::Gone)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises PreconditionFailed on 412" do
    expect { response_status 412 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::PreconditionFailed)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises UnprocessableEntity on 422" do
    expect { response_status 422 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::UnprocessableEntity)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises Locked on 423" do
    expect { response_status 423 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::Locked)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises TooManyRequests on 429" do
    expect { response_status 429 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::TooManyRequests)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises InternalServerError on 500" do
    expect { response_status 500 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::InternalServerError)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises BadGateway on 502" do
    expect { response_status 502 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::BadGateway)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises ServiceUnavailable on 503" do
    expect { response_status 503 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::ServiceUnavailable)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises GatewayTimeout on 504" do
    expect { response_status 504 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::GatewayTimeout)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises ClientError on statuses in the 4XX range" do
    expect { response_status 400 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::ClientError)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end

    expect { response_status 499 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::ClientError)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  it "raises ServerError on statuses in the 5XX range" do
    expect { response_status 500 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::ServerError)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end

    expect { response_status 599 }.to raise_error do |error|
      expect(error).to be_a(CloudflareClient::ServerError)
      expect(error.uri).to eq('/foo')
      expect(error.url).to eq('https://example.com/foo')
      expect(error.method).to eq(:get)
    end
  end

  describe "ResponseError" do
    context "#initialize" do
      it 'can be instantiated with nil params' do
        CloudflareClient::ResponseError.new
      end
    end
  end

  def response_status(status)
    service.get('/foo') { status }
    connection.get('/foo')
  end
end
