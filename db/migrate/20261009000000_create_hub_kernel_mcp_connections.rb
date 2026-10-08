class CreateHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :hub_kernel_mcp_connections do |t|
      t.string :token_digest, null: false, index: { unique: true }
      t.references :client, null: false, foreign_key: { to_table: :hub_kernel_mcp_clients }
      t.string :person_gid, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
