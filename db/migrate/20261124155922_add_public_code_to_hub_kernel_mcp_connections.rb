class AddPublicCodeToHubKernelMcpConnections < ActiveRecord::Migration[8.1]
  class Connection < ActiveRecord::Base
    self.table_name = "hub_kernel_mcp_connections"
  end

  def change
    add_column :hub_kernel_mcp_connections, :public_code, :string

    reversible do |direction|
      direction.up do
        Connection.reset_column_information
        Connection.where(public_code: nil).find_each do |connection|
          connection.update_columns(public_code: Connection.generate_unique_secure_token)
        end
      end
    end
  end
end
