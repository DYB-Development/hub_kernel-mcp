class CreateHubKernelMcpClients < ActiveRecord::Migration[8.1]
  def change
    create_table :hub_kernel_mcp_clients do |t|
      t.string :uid, null: false, index: { unique: true }
      t.string :name
      t.json :redirect_uris, null: false
      t.timestamps
    end
  end
end
