require "test_helper"

class ApprovalTest < ActionDispatch::IntegrationTest
  setup do
    @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    @approval = { response_type: "code", client_id: @client.uid, redirect_uri: "https://claude.ai/callback", state: "xyz", code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM", code_challenge_method: "S256" }
  end

  test "a person who is not signed in is sent to the host's sign-in and returned to the approval page" do
    get "/mcp/authorize", params: @approval
    get response.location, params: { person: "sam" }

    assert_redirected_to "http://www.example.com/mcp/authorize?#{URI.encode_www_form(@approval)}"
  end

  test "a signed-in person sees the app asking to connect with an Approve and a Deny button in the host's layout" do
    sign_in "sam"

    get "/mcp/authorize", params: @approval

    assert_equal [ "Dummy", "Claude wants to connect as you", [ "Approve", "Deny" ] ], [ css_select("title").text, css_select("h1").text, css_select("button").map(&:text) ]
  end

  test "a person who approves is sent back to the client's redirect address with a code and the client's state" do
    sign_in "sam"

    post "/mcp/authorize", params: @approval.merge(decision: "approve")

    answer = Rack::Utils.parse_query(URI(response.location).query)
    assert_equal [ "https://claude.ai/callback", "xyz", HubKernel::Mcp::AuthorizationCode.sole.code_digest ], [ response.location.split("?").first, answer["state"], HubKernel::Mcp::AuthorizationCode.digest(answer["code"]) ]
  end

  test "a person who denies is sent back to the client's redirect address with an access-denied error and no code" do
    sign_in "sam"

    post "/mcp/authorize", params: @approval.merge(decision: "deny")

    assert_equal [ "https://claude.ai/callback?error=access_denied&state=xyz", 0 ], [ response.location, HubKernel::Mcp::AuthorizationCode.count ]
  end

  private

  def sign_in(person) = get("/sign_in", params: { person: person, return_to: "/" })
end
