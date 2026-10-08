require "test_helper"

class RegistrationTest < ActionDispatch::IntegrationTest
  test "a client that registers its name and redirect addresses gets a client id" do
    post "/mcp/register", params: { client_name: "Claude", redirect_uris: [ "https://claude.ai/api/mcp/auth_callback" ] }, as: :json

    assert_equal [ 201, HubKernel::Mcp::Client.sole.uid ], [ response.status, response.parsed_body["client_id"] ]
  end

  test "a client registering an address it may not redirect to is refused with the reason" do
    post "/mcp/register", params: { client_name: "Claude", redirect_uris: [ "http://claude.ai/callback" ] }, as: :json

    assert_equal [ 400, { "error" => "invalid_redirect_uri", "error_description" => "http://claude.ai/callback is neither HTTPS nor on the client's own machine" } ], [ response.status, response.parsed_body ]
  end

  test "a registration whose body is not valid JSON is answered with the OAuth error and why" do
    post "/mcp/register", params: "{", headers: { "Content-Type" => "application/json" }

    assert_equal [ 400, { "error" => "invalid_client_metadata", "error_description" => "The registration body is not valid JSON" } ], [ response.status, response.parsed_body ]
  end
end
