module ResponseHelper
  def response_body(body)
    if body.is_a?(Hash)
      {body: body.to_json, headers: {'Content-Type': 'application/json'}}
    else
      {body: body, headers: {'Content-Type': 'application/json'}}
    end
  end
end

RSpec.configure { |config| config.include ResponseHelper }
