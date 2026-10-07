require "test_helper"

class ErrorsTest < ActionDispatch::IntegrationTest
  module Boiler
    extend HubKernel::Exposes

    exposes :heat, takes: [], writes: true

    def self.heat = raise("the boiler password is hunter2")
  end

  setup do
    @hubs = HubKernel::Interface.hubs
    HubKernel::Interface.hubs = @hubs + [ Boiler ]
  end

  teardown { HubKernel::Interface.hubs = @hubs }

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

  test "a ping is answered with an empty result" do
    post "/mcp", params: { jsonrpc: "2.0", id: 5, method: "ping" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "jsonrpc" => "2.0", "id" => 5, "result" => {} }, response.parsed_body)
  end

  test "a GET to the address is answered as method not allowed" do
    get "/mcp", headers: { "X-Person" => "sam", "X-Account" => "acme" }

    assert_response :method_not_allowed
  end

  test "an unexpected error inside a hub method is answered as an internal error without its message" do
    post "/mcp", params: { jsonrpc: "2.0", id: 6, method: "tools/call", params: { name: "boiler__heat" } }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "jsonrpc" => "2.0", "id" => 6, "error" => { "code" => -32603, "message" => "Internal error" } }, response.parsed_body)
  end
end
