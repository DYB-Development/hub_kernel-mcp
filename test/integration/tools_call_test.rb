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

  test "a tool that does not exist is answered with an unknown-tool error" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "shop__close_shop", arguments: {} } }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "code" => -32602, "message" => "Unknown tool: shop__close_shop" }, response.parsed_body["error"])
  end

  test "a tool naming a hub the host does not serve is answered with an unknown-tool error" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "back_office__close_books", arguments: {} } }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal "Unknown tool: back_office__close_books", response.parsed_body.dig("error", "message")
  end

  test "a tool the caller may not call is answered the same way as a tool that does not exist" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "shop__restock", arguments: { item: "soap", count: 4 } } }, headers: { "X-Person" => "lee", "X-Account" => "acme" }, as: :json

    assert_equal({ "code" => -32602, "message" => "Unknown tool: shop__restock" }, response.parsed_body["error"])
  end
end
