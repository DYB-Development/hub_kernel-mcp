require "test_helper"

class HubKernel::Mcp::ConnectionTest < ActiveSupport::TestCase
  setup { @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ]) }

  test "an issued access token is kept only as its digest, holding who it acts for and which client holds it" do
    token = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)

    stored = HubKernel::Mcp::Connection.sole
    assert_equal [ Digest::SHA256.hexdigest(token), Person.new("sam"), @client ], [ stored.token_digest, stored.person, stored.client ]
  end
end
