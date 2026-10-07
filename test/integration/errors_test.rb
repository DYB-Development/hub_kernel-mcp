require "test_helper"

class ErrorsTest < ActionDispatch::IntegrationTest
  test "a request body that is not valid JSON is answered with a parse error" do
    post "/mcp", params: "{not json", headers: { "Content-Type" => "application/json", "X-Person" => "sam", "X-Account" => "acme" }

    assert_equal({ "jsonrpc" => "2.0", "id" => nil, "error" => { "code" => -32700, "message" => "Parse error" } }, response.parsed_body)
  end

  test "a batch of requests is answered with an invalid-request error" do
    post "/mcp", params: [ { jsonrpc: "2.0", id: 1, method: "tools/list" } ].to_json, headers: { "Content-Type" => "application/json", "X-Person" => "sam", "X-Account" => "acme" }

    assert_equal({ "jsonrpc" => "2.0", "id" => nil, "error" => { "code" => -32600, "message" => "Invalid Request" } }, response.parsed_body)
  end

  test "a request naming a method the server does not support is answered with a method-not-found error" do
    post "/mcp", params: { jsonrpc: "2.0", id: 4, method: "resources/list" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "jsonrpc" => "2.0", "id" => 4, "error" => { "code" => -32601, "message" => "Method not found: resources/list" } }, response.parsed_body)
  end
end
