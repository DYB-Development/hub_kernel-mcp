class AddAccountGidToHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :hub_kernel_mcp_connections, :account_gid, :string
  end
end
