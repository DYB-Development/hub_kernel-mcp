require "test_helper"

class SignInTest < ActionDispatch::IntegrationTest
  setup { @check = HubKernel::Authz.check }
  teardown { HubKernel::Authz.check = @check }

  test "a caller the host's sign-in refuses is refused before any hub is asked" do
    asked = []
    HubKernel::Authz.check = ->(*args) { asked << args; true }

    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, as: :json

    assert_equal [ 401, [] ], [ response.status, asked ]
  end

  test "a caller the host's sign-in refuses is told where the endpoint's sign-in is described" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, as: :json

    assert_equal 'Bearer resource_metadata="http://www.example.com/.well-known/oauth-protected-resource/mcp"', response.headers["WWW-Authenticate"]
  end
end
