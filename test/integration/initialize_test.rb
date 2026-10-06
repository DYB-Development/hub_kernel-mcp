require "test_helper"

class InitializeTest < ActionDispatch::IntegrationTest
  test "a client that sends initialize gets the server's name, its version and a tools capability" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "1" } } }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "serverInfo" => { "name" => "hub_kernel-mcp", "version" => HubKernel::Mcp::VERSION }, "capabilities" => { "tools" => {} } }, response.parsed_body["result"].slice("serverInfo", "capabilities"))
  end

  test "a client asking for a protocol version the gem supports gets that version back" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2025-03-26" } }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal "2025-03-26", response.parsed_body.dig("result", "protocolVersion")
  end
end
