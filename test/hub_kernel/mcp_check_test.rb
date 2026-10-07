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
end
