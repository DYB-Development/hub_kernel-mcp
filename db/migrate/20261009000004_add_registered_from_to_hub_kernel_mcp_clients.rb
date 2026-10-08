class AddRegisteredFromToHubKernelMcpClients < ActiveRecord::Migration[8.1]
  def change
    add_column :hub_kernel_mcp_clients, :registered_from, :string
    add_index :hub_kernel_mcp_clients, [ :registered_from, :created_at ]
  end
end
