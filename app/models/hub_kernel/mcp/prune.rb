module HubKernel
  module Mcp
    module Prune
      def self.call
        now = Time.current
        AuthorizationCode.where(expires_at: ...now).delete_all
        Connection.where(expires_at: ...now).where("refresh_expires_at IS NULL OR refresh_expires_at < ?", now).delete_all
        Client.where(created_at: ...1.day.ago).where.not(id: Connection.select(:client_id)).where.not(id: AuthorizationCode.select(:client_id)).delete_all
      end
    end
  end
end
