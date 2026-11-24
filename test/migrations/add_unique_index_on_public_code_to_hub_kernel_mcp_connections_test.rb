require "test_helper"
require_relative "../../db/migrate/20261124172809_add_unique_index_on_public_code_to_hub_kernel_mcp_connections"

class AddUniqueIndexOnPublicCodeToHubKernelMcpConnectionsTest < ActiveSupport::TestCase
  setup do
    @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    @migration = AddUniqueIndexOnPublicCodeToHubKernelMcpConnections.new.tap { |it| it.verbose = false }
  end

  test "installing the index migration refuses two connections the same public code" do
    ActiveRecord::Base.connection.remove_index :hub_kernel_mcp_connections, :public_code
    2.times { HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client) }
    first, second = HubKernel::Mcp::Connection.order(:id).to_a

    @migration.migrate(:up)

    assert_raises(ActiveRecord::RecordNotUnique) { second.update_columns(public_code: first.public_code) }
  end

  test "installing the index migration on a host that already has the index from 0.12.0 runs" do
    assert_nothing_raised { @migration.migrate(:up) }
  end
end
