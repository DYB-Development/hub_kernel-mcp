class AddLastUsedAtToHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :hub_kernel_mcp_connections, :last_used_at, :datetime
  end
end
