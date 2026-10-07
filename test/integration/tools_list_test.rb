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

  test "a method of a hub that is not on the served list is not listed" do
    BackOffice.exposures

    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_not_includes response.parsed_body.dig("result", "tools").map { |tool| tool["name"] }, "back_office__close_books"
  end

  test "a tool for a method that only reads is marked read-only" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    price_of = response.parsed_body.dig("result", "tools").find { |tool| tool["name"] == "shop__price_of" }
    assert_equal true, price_of.dig("annotations", "readOnlyHint")
  end

  test "a tool for a method that writes is marked as one that changes data" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    restock = response.parsed_body.dig("result", "tools").find { |tool| tool["name"] == "shop__restock" }
    assert_equal false, restock.dig("annotations", "readOnlyHint")
  end

  test "every tool carries a description naming its hub and saying whether it reads or changes data" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    descriptions = response.parsed_body.dig("result", "tools").to_h { |tool| [ tool["name"], tool["description"] ] }
    assert_equal({ "shop__price_of" => "Reads data from the shop hub.", "shop__restock" => "Changes data in the shop hub.", "money__record_spend" => "Changes data in the money hub." }, descriptions)
  end
end
