require "test_helper"

class HubKernel::Mcp::AuthorizationCodeTest < ActiveSupport::TestCase
  test "an issued code is kept only as its digest, holding who approved which client" do
    client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])

    code = HubKernel::Mcp::AuthorizationCode.issue(person: Person.new("sam"), client: client, redirect_uri: "https://claude.ai/callback", code_challenge: "challenge")

    stored = HubKernel::Mcp::AuthorizationCode.sole
    assert_equal [ Digest::SHA256.hexdigest(code), Person.new("sam"), client ], [ stored.code_digest, stored.person, stored.client ]
  end

  test "a code accepts only the PKCE verifier whose SHA-256 matches its challenge" do
    code = HubKernel::Mcp::AuthorizationCode.new(code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")

    assert_equal [ true, false ], [ code.verifies?("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"), code.verifies?("another-verifier") ]
  end
end
