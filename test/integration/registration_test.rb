require "test_helper"

class RegistrationTest < ActionDispatch::IntegrationTest
  test "a client that registers its name and redirect addresses gets a client id" do
    post "/mcp/register", params: { client_name: "Claude", redirect_uris: [ "https://claude.ai/api/mcp/auth_callback" ] }, as: :json

    assert_equal [ 201, HubKernel::Mcp::Client.sole.uid ], [ response.status, response.parsed_body["client_id"] ]
  end
end
