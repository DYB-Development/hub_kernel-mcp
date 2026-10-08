require "test_helper"

class HubKernel::Mcp::ClientTest < ActiveSupport::TestCase
  test "a client with no redirect address says it needs one" do
    client = HubKernel::Mcp::Client.new(name: "Claude", redirect_uris: [])

    assert_equal [ false, [ "A client must register at least one redirect address" ] ], [ client.valid?, client.errors.full_messages ]
  end
end
