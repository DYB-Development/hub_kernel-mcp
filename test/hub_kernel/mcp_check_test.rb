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

  test "a tool name holding a character other than a letter, a digit, an underscore or a hyphen is named" do
    HubKernel::Interface.hubs = [ { "money box" => Ledger } ]

    error = assert_raises(HubKernel::Mcp::UnservableHubError) { HubKernel::Mcp.check! }

    assert_equal "The tool money box__record_spend holds a character other than a letter, a digit, an underscore or a hyphen", error.message
  end

  test "a tool name longer than 64 characters is named" do
    HubKernel::Interface.hubs = [ { "m" * 51 => Ledger } ]

    error = assert_raises(HubKernel::Mcp::UnservableHubError) { HubKernel::Mcp.check! }

    assert_equal "The tool #{"m" * 51}__record_spend is longer than 64 characters", error.message
  end

  test "a served list with no problem passes the check" do
    HubKernel::Interface.hubs = [ Shop, { "money" => Ledger } ]

    assert_nil HubKernel::Mcp.check!
  end

  test "every problem is named in one error" do
    HubKernel::Interface.hubs = [ Silent, { "money box" => Ledger } ]

    error = assert_raises(HubKernel::Mcp::UnservableHubError) { HubKernel::Mcp.check! }

    assert_equal [ "McpCheckTest::Silent exposes no methods to serve", "The tool money box__record_spend holds a character other than a letter, a digit, an underscore or a hyphen" ], error.message.lines(chomp: true)
  end
end
