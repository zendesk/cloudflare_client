class CloudflareClient
  class ResponseError < StandardError
    # The Faraday::Response object that caused the exception to be raised.
    attr_reader :response, :method, :uri, :url

    def initialize(message = nil, response = nil, method = nil, uri = nil, url = nil)
      super("#{message}, #{method.upcase} #{url} #{response.body}")
      @response = response
      @method = method
      @uri = uri
      @url = url
    end
  end

  # An exception that is raised when a response status in the 4xx range is
  # encountered. There's a number of subclasses that allow you to granularly
  # handle specific status codes.
  class ClientError < ResponseError; end

  # Client errors:
  class BadRequest < ClientError; end
  class Unauthorized < ClientError; end
  class Forbidden < ClientError; end
  class ResourceNotFound < ClientError; end
  class Conflict < ClientError; end
  class Gone < ClientError; end
  class PreconditionFailed < ClientError; end
  class UnprocessableEntity < ClientError; end
  class TooManyRequests < ClientError; end
  class Locked < ClientError; end

  # An exception that is raised when a response status in the 5xx range is
  # encountered. There's a number of subclasses that allow you to granularly
  # handle specific status codes.
  class ServerError < ResponseError; end

  # Server errors:
  class InternalServerError < ServerError; end
  class BadGateway < ServerError; end
  class ServiceUnavailable < ServerError; end
  class GatewayTimeout < ServerError; end

  module Middleware
    module Response
      # Raises ResponseError exceptions when a response status in either the
      # 4xx range or the 5xx range is encountered. There are a number of specific
      # exception mappings as well as general exception types covering the
      # respective ranges.
      class RaiseError
        CLIENT_ERRORS = 400...500
        SERVER_ERRORS = 500...600

        def initialize(app)
          @app = app
        end

        def call(env)
          response = @app.call(env)
          handle_status(response, env.method, env.url.request_uri, env.url.to_s)
          response
        end

        private

        def handle_status(response, method, uri, url)
          case response.status
          when 400
            raise CloudflareClient::BadRequest.new('400 Bad Request', response, method, uri, url)
          when 401
            raise CloudflareClient::Unauthorized.new('401 Unauthorized', response, method, uri, url)
          when 403
            raise CloudflareClient::Forbidden.new('403 Forbidden', response, method, uri, url)
          when 404
            raise CloudflareClient::ResourceNotFound.new('404 Not Found', response, method, uri, url)
          when 407
            # Mimic the behavior that we get with proxy requests with HTTPS. We still
            # use Faraday exceptions for network errors, as it's difficult to reliably
            # wrap these in CloudflareClient without losing information.
            raise Faraday::ConnectionFailed.new('407 Proxy Authentication Required', response)
          when 409
            raise CloudflareClient::Conflict.new('409 Conflict', response, method, uri, url)
          when 410
            raise CloudflareClient::Gone.new('410 Gone', response, method, uri, url)
          when 412
            raise CloudflareClient::PreconditionFailed.new('412 Precondition Failed', response, method, uri, url)
          when 422
            raise CloudflareClient::UnprocessableEntity.new('422 Unprocessable Entity', response, method, uri, url)
          when 423
            raise CloudflareClient::Locked.new('423 Locked', response, method, uri, url)
          when 429
            raise CloudflareClient::TooManyRequests.new('429 Too Many Requests', response, method, uri, url)
          when 500
            raise CloudflareClient::InternalServerError.new('500 Internal Server Error', response, method, uri, url)
          when 502
            raise CloudflareClient::BadGateway.new('502 Bad Gateway', response, method, uri, url)
          when 503
            raise CloudflareClient::ServiceUnavailable.new('503 Service Unavailable', response, method, uri, url)
          when 504
            raise CloudflareClient::GatewayTimeout.new('504 Gateway Timeout', response, method, uri, url)
          when CLIENT_ERRORS
            raise CloudflareClient::ClientError.new(response.status.to_s, response, method, uri, url)
          when SERVER_ERRORS
            raise CloudflareClient::ServerError.new(response.status.to_s, response, method, uri, url)
          end
        end
      end
    end
  end
end
