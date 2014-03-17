require 'net/http'

class FakeHttpResponse < Net::HTTPSuccess
  def initialize(code, body)
    @code = code
    @body = body
  end
  def code
    @code
  end
  def body
    @body
  end
end