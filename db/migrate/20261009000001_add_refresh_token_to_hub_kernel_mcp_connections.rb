class AddRefreshTokenToHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :hub_kernel_mcp_connections, :refresh_token_digest, :string
    add_column :hub_kernel_mcp_connections, :refresh_expires_at, :datetime
    add_index :hub_kernel_mcp_connections, :refresh_token_digest, unique: true
  end
end
