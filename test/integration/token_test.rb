require "test_helper"

class TokenTest < ActionDispatch::IntegrationTest
  setup do
    @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    @code = HubKernel::Mcp::AuthorizationCode.issue(person: Person.new("sam"), client: @client, redirect_uri: "https://claude.ai/callback", code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    @exchange = { grant_type: "authorization_code", code: @code, code_verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk", redirect_uri: "https://claude.ai/callback", client_id: @client.uid }
  end

  test "a client posting a code with its verifier and redirect address gets an access token and how many seconds it lasts" do
    post "/mcp/token", params: @exchange

    answer = response.parsed_body
    assert_equal [ 200, "Bearer", 3600, HubKernel::Mcp::Connection.sole.token_digest ], [ response.status, answer["token_type"], answer["expires_in"], HubKernel::Mcp::Connection.digest(answer["access_token"].to_s) ]
  end
end
