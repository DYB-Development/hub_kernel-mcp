class CreateHubKernelMcpAuthorizationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :hub_kernel_mcp_authorization_codes do |t|
      t.string :code_digest, null: false, index: { unique: true }
      t.references :client, null: false, foreign_key: { to_table: :hub_kernel_mcp_clients }
      t.string :person_gid, null: false
      t.string :redirect_uri, null: false
      t.string :code_challenge, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
