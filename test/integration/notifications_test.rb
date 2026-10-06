require "test_helper"

class NotificationsTest < ActionDispatch::IntegrationTest
  test "a notification from the client is accepted with no answer" do
    post "/mcp", params: { jsonrpc: "2.0", method: "notifications/initialized" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ 202, "" ], [ response.status, response.body ]
  end
end
