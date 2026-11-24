require "test_helper"
require_relative "../../db/migrate/20261124155922_add_public_code_to_hub_kernel_mcp_connections"
require_relative "../../db/migrate/20261124172809_add_unique_index_on_public_code_to_hub_kernel_mcp_connections"

class AddPublicCodeToHubKernelMcpConnectionsTest < ActiveSupport::TestCase
  setup { @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ]) }

  teardown { HubKernel::Mcp::Connection.reset_column_information }

  test "installing both migrations gives every existing connection a public code" do
    2.times { HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client) }
    column = AddPublicCodeToHubKernelMcpConnections.new.tap { |it| it.verbose = false }
    index = AddUniqueIndexOnPublicCodeToHubKernelMcpConnections.new.tap { |it| it.verbose = false }

    index.migrate(:down)
    column.migrate(:down)
    column.migrate(:up)
    index.migrate(:up)
    HubKernel::Mcp::Connection.reset_column_information

    assert_equal 2, HubKernel::Mcp::Connection.where.not(public_code: nil).distinct.count(:public_code)
  end
end
