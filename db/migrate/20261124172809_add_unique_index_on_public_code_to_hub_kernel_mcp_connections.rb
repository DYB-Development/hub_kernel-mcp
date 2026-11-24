class AddUniqueIndexOnPublicCodeToHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :hub_kernel_mcp_connections, :public_code, unique: true, if_not_exists: true, **concurrently
  end

  private

  def concurrently
    connection.index_algorithms.key?(:concurrently) ? { algorithm: :concurrently } : {}
  end
end
