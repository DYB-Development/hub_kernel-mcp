require "test_helper"

class HubKernel::Mcp::ClientTest < ActiveSupport::TestCase
  test "a client with no redirect address says it needs one" do
    client = HubKernel::Mcp::Client.new(name: "Claude", redirect_uris: [])

    assert_equal [ false, [ "A client must register at least one redirect address" ] ], [ client.valid?, client.errors.full_messages ]
  end

  test "a client may only redirect to an HTTPS address or one on its own machine" do
    addresses = %w[https://claude.ai/callback http://localhost:6274/callback http://127.0.0.1/callback http://[::1]/callback http://claude.ai/callback javascript:alert(1)]
    client = HubKernel::Mcp::Client.new(name: "Claude", redirect_uris: addresses)

    assert_equal [ false, [ "http://claude.ai/callback is neither HTTPS nor on the client's own machine", "javascript:alert(1) is neither HTTPS nor on the client's own machine" ] ], [ client.valid?, client.errors.full_messages ]
  end
end
