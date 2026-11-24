class AddPublicCodeToHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :hub_kernel_mcp_connections, :public_code, :string
  end
end
