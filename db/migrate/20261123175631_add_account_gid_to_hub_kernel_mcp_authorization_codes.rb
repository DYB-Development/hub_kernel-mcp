class AddAccountGidToHubKernelMcpAuthorizationCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :hub_kernel_mcp_authorization_codes, :account_gid, :string
  end
end
