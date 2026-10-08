class AddCodeDigestToHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :hub_kernel_mcp_connections, :code_digest, :string
    add_index :hub_kernel_mcp_connections, :code_digest
  end
end
