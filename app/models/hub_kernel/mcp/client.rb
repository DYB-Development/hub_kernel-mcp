module HubKernel
  module Mcp
    class Client < ActiveRecord::Base
      has_secure_token :uid

      validate :redirect_uris_named

      private

      def redirect_uris_named
        errors.add(:base, "A client must register at least one redirect address") if redirect_uris.blank?
      end
    end
  end
end
