require "test_helper"

class ConnectorSignInTest < ActionDispatch::IntegrationTest
  VERIFIER = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk".freeze
  CHALLENGE = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM".freeze
  CALLBACK = "https://claude.ai/callback".freeze

  test "a client that registers, is approved and trades its code lists the person's tools with only its access token" do
    post "/mcp/register", params: { client_name: "Claude", redirect_uris: [ CALLBACK ] }, as: :json
    client_id = response.parsed_body["client_id"]
    get "/sign_in", params: { person: "sam", return_to: "/" }
    post "/mcp/authorize", params: { response_type: "code", client_id: client_id, redirect_uri: CALLBACK, state: "xyz", code_challenge: CHALLENGE, code_challenge_method: "S256", decision: "approve" }
    code = Rack::Utils.parse_query(URI(response.location).query)["code"]
    post "/mcp/token", params: { grant_type: "authorization_code", code: code, code_verifier: VERIFIER, redirect_uri: CALLBACK, client_id: client_id }
    token = response.parsed_body["access_token"]

    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    assert_equal %w[shop__price_of shop__restock money__record_spend], response.parsed_body.dig("result", "tools")&.map { |tool| tool["name"] }
  end
end
