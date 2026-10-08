module HubKernel
  module Mcp
    module Prune
      def self.call
        AuthorizationCode.where(expires_at: ...Time.current).delete_all
      end
    end
  end
end
