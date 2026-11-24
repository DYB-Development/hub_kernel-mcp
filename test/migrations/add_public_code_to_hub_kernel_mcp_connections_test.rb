require "test_helper"
require_relative "../../db/migrate/20261124155922_add_public_code_to_hub_kernel_mcp_connections"

class AddPublicCodeToHubKernelMcpConnectionsTest < ActiveSupport::TestCase
  setup { @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ]) }

  teardown { HubKernel::Mcp::Connection.reset_column_information }

  test "installing the migration gives every existing connection a public code" do
    2.times { HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client) }
    migration = AddPublicCodeToHubKernelMcpConnections.new.tap { |it| it.verbose = false }

    migration.migrate(:down)
    migration.migrate(:up)
    HubKernel::Mcp::Connection.reset_column_information

    assert_equal 2, HubKernel::Mcp::Connection.where.not(public_code: nil).distinct.count(:public_code)
  end
end
