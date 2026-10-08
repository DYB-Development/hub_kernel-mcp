require "test_helper"

class HubKernel::Mcp::AuthorizationCodeTest < ActiveSupport::TestCase
  test "an issued code is kept only as its digest, holding who approved which client" do
    client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])

    code = HubKernel::Mcp::AuthorizationCode.issue(person: Person.new("sam"), client: client, redirect_uri: "https://claude.ai/callback", code_challenge: "challenge")

    stored = HubKernel::Mcp::AuthorizationCode.sole
    assert_equal [ Digest::SHA256.hexdigest(code), Person.new("sam"), client ], [ stored.code_digest, stored.person, stored.client ]
  end
end
