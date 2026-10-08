require "test_helper"

class RegistrationTest < ActionDispatch::IntegrationTest
  setup { @limit = HubKernel::Mcp.registration_limit }
  teardown { HubKernel::Mcp.registration_limit = @limit }

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

  test "an unexpected error at the registration address is reported without its message reaching the client" do
    reports = while_failing(HubKernel::Mcp::Client, :new) do
      capture_error_reports { post "/mcp/register", params: { client_name: "Claude", redirect_uris: [ "https://claude.ai/callback" ] }, as: :json }
    end

    assert_equal [ [ RuntimeError ], 500, { "error" => "server_error", "error_description" => "The sign-in failed unexpectedly" } ], [ reports.map { |report| report.error.class }, response.status, response.parsed_body ]
  end

  test "registrations from one address past the host's hourly limit are refused with the reason" do
    HubKernel::Mcp.registration_limit = 2
    3.times { post "/mcp/register", params: { client_name: "Claude", redirect_uris: [ "https://claude.ai/callback" ] }, as: :json }

    assert_equal [ 429, { "error" => "too_many_registrations", "error_description" => "This address has registered 2 clients in the last hour, which is the limit" }, 2 ], [ response.status, response.parsed_body, HubKernel::Mcp::Client.count ]
  end
end
