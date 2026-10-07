require "test_helper"

class ToolsCallTest < ActionDispatch::IntegrationTest
  test "a tools/call naming a listed tool runs the hub's method and returns its answer as the tool result" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "shop__price_of", arguments: { item: "soap" } } }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "content" => [ { "type" => "text", "text" => "\"soap costs 3\"" } ], "isError" => false }, response.parsed_body["result"])
  end

  test "a method that writes can be called as a tool" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "shop__restock", arguments: { item: "soap", count: 4 } } }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal "\"4 soap restocked\"", response.parsed_body.dig("result", "content", 0, "text")
  end
end
