require "test_helper"

class ToolsListTest < ActionDispatch::IntegrationTest
  test "a tools/list request returns one tool for each method the caller may call across every served hub" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal %w[shop__price_of shop__restock money__record_spend], response.parsed_body.dig("result", "tools").map { |tool| tool["name"] }
  end

  test "each listed tool carries an input schema naming the values its method takes" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    restock = response.parsed_body.dig("result", "tools").find { |tool| tool["name"] == "shop__restock" }
    assert_equal({ "type" => "object", "properties" => { "item" => {}, "count" => {} } }, restock["inputSchema"])
  end

  test "a method the host's permission check refuses for the caller is not listed" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "X-Person" => "lee", "X-Account" => "acme" }, as: :json

    assert_equal %w[shop__price_of], response.parsed_body.dig("result", "tools").map { |tool| tool["name"] }
  end
end
