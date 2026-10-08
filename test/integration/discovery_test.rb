require "test_helper"

class DiscoveryTest < ActionDispatch::IntegrationTest
  test "the endpoint's description names the endpoint and its sign-in" do
    get "/.well-known/oauth-protected-resource/mcp"

    assert_equal({ "resource" => "http://www.example.com/mcp", "authorization_servers" => [ "http://www.example.com" ] }, response.parsed_body)
  end

  test "the sign-in's description names its addresses and requires PKCE with SHA-256" do
    get "/.well-known/oauth-authorization-server"

    assert_equal({
      "issuer" => "http://www.example.com",
      "registration_endpoint" => "http://www.example.com/mcp/register",
      "authorization_endpoint" => "http://www.example.com/mcp/authorize",
      "token_endpoint" => "http://www.example.com/mcp/token",
      "response_types_supported" => [ "code" ],
      "grant_types_supported" => [ "authorization_code" ],
      "token_endpoint_auth_methods_supported" => [ "none" ],
      "code_challenge_methods_supported" => [ "S256" ]
    }, response.parsed_body)
  end
end
