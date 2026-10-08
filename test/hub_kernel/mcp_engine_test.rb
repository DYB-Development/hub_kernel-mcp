require "test_helper"

class McpEngineTest < ActiveSupport::TestCase
  test "the gem's views are among the files a host's Tailwind build scans" do
    assert_includes KeystoneUi.configuration.tailwind_sources, HubKernel::Mcp::Engine.root.join("app/views/**/*.erb").to_s
  end
end
