require "test_helper"

class ErrorsTest < ActionDispatch::IntegrationTest
  test "a request body that is not valid JSON is answered with a parse error" do
    post "/mcp", params: "{not json", headers: { "Content-Type" => "application/json", "X-Person" => "sam", "X-Account" => "acme" }

    assert_equal({ "jsonrpc" => "2.0", "id" => nil, "error" => { "code" => -32700, "message" => "Parse error" } }, response.parsed_body)
  end
end
