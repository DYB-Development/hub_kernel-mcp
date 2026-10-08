require "test_helper"

class DiscoveryTest < ActionDispatch::IntegrationTest
  test "the endpoint's description names the endpoint and its sign-in" do
    get "/.well-known/oauth-protected-resource/mcp"

    assert_equal({ "resource" => "http://www.example.com/mcp", "authorization_servers" => [ "http://www.example.com" ] }, response.parsed_body)
  end
end
