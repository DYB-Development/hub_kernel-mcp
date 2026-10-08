require "digest"
require "securerandom"

module HubKernel
  module Mcp
    class Connection < ActiveRecord::Base
      LIFETIME = 1.hour

      belongs_to :client

      def self.issue(person:, client:)
        token = SecureRandom.urlsafe_base64(32)
        create!(token_digest: digest(token), person_gid: person.to_global_id.to_s, client: client, expires_at: LIFETIME.from_now)
        token
      end

      def self.digest(token) = Digest::SHA256.hexdigest(token)

      def person = GlobalID::Locator.locate(person_gid)
    end
  end
end
