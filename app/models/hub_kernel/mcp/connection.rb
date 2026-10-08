require "digest"
require "securerandom"

module HubKernel
  module Mcp
    class Connection < ActiveRecord::Base
      LIFETIME = 1.hour
      REFRESH_LIFETIME = 90.days

      Tokens = Data.define(:access_token, :refresh_token)

      belongs_to :client

      def self.issue(person:, client:)
        tokens = new_tokens
        create!(person_gid: person.to_global_id.to_s, client: client, **digests_for(tokens))
        tokens
      end

      def self.refresh(refresh_token, client:)
        connection = where(refresh_expires_at: Time.current..).find_by(refresh_token_digest: digest(refresh_token.to_s), client: client)
        return unless connection

        tokens = new_tokens
        renewed = where(id: connection.id, refresh_token_digest: connection.refresh_token_digest).update_all(updated_at: Time.current, **digests_for(tokens))
        tokens if renewed == 1
      end

      def self.person_for(token) = where(expires_at: Time.current..).find_by(token_digest: digest(token.to_s))&.person

      def self.digest(token) = Digest::SHA256.hexdigest(token)

      def self.new_tokens = Tokens.new(access_token: SecureRandom.urlsafe_base64(32), refresh_token: SecureRandom.urlsafe_base64(32))

      def self.digests_for(tokens)
        { token_digest: digest(tokens.access_token), refresh_token_digest: digest(tokens.refresh_token), expires_at: LIFETIME.from_now, refresh_expires_at: REFRESH_LIFETIME.from_now }
      end

      private_class_method :new_tokens, :digests_for

      def person = GlobalID::Locator.locate(person_gid)
    end
  end
end
