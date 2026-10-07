require "test_helper"

class McpCheckTest < ActiveSupport::TestCase
  module Silent
    extend HubKernel::Exposes
  end

  setup { @served = HubKernel::Interface.hubs }
  teardown { HubKernel::Interface.hubs = @served }

  test "a host serving hubs only over MCP has its served list checked with the shared messages" do
    HubKernel::Interface.hubs = [ Silent ]

    error = assert_raises(HubKernel::Mcp::UnservableHubError) { HubKernel::Mcp.check! }

    assert_equal "McpCheckTest::Silent exposes no methods to serve", error.message
  end

  test "a served name holding two underscores in a row is named with its hub" do
    HubKernel::Interface.hubs = [ { "back__room" => Shop } ]

    error = assert_raises(HubKernel::Mcp::UnservableHubError) { HubKernel::Mcp.check! }

    assert_equal "Shop is served at back__room, which holds two underscores in a row", error.message
  end
end
