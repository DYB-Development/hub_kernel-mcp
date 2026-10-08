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

  test "a code posted with a verifier that does not match its challenge is refused and gives no token" do
    post "/mcp/token", params: @exchange.merge(code_verifier: "another-verifier")

    assert_refused
  end

  test "a code posted with a redirect address other than the one it was approved for is refused and gives no token" do
    post "/mcp/token", params: @exchange.merge(redirect_uri: "https://claude.ai/other")

    assert_refused
  end

  test "a code used a second time is refused and gives no second token" do
    post "/mcp/token", params: @exchange
    post "/mcp/token", params: @exchange

    assert_equal [ 400, { "error" => "invalid_grant", "error_description" => "The code is unknown, used, expired, or does not match this client, redirect address or verifier" }, 1 ], [ response.status, response.parsed_body, HubKernel::Mcp::Connection.count ]
  end

  test "a code posted more than ten minutes after it was made is refused and gives no token" do
    travel 10.minutes + 1.second

    post "/mcp/token", params: @exchange

    assert_refused
  end

  test "a code posted with another client's id is refused and gives no token" do
    other = HubKernel::Mcp::Client.create!(name: "Other", redirect_uris: [ "https://claude.ai/callback" ])

    post "/mcp/token", params: @exchange.merge(client_id: other.uid)

    assert_refused
  end

  test "a client trading a code also gets a refresh token" do
    post "/mcp/token", params: @exchange

    assert_equal HubKernel::Mcp::Connection.sole.refresh_token_digest, HubKernel::Mcp::Connection.digest(response.parsed_body["refresh_token"].to_s)
  end

  test "a client posting its refresh token gets a new access token and a new refresh token" do
    post "/mcp/token", params: @exchange
    first = response.parsed_body

    post "/mcp/token", params: { grant_type: "refresh_token", refresh_token: first["refresh_token"], client_id: @client.uid }

    answer = response.parsed_body
    assert_equal [ 200, Person.new("sam"), false ], [ response.status, HubKernel::Mcp::Connection.person_for(answer["access_token"]), answer["refresh_token"].in?([ nil, first["refresh_token"] ]) ]
  end

  private

  def assert_refused
    assert_equal [ 400, { "error" => "invalid_grant", "error_description" => "The code is unknown, used, expired, or does not match this client, redirect address or verifier" }, 0 ], [ response.status, response.parsed_body, HubKernel::Mcp::Connection.count ]
  end
end
