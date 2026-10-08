module HubKernel
  module Mcp
    class Disconnect
      Result = Data.define(:message) do
        def ok? = message.nil?
      end

      def initialize(values:, person: nil, account: nil)
        @person = person
        @values = values
      end

      def call
        disconnected = Connection.of(@person).where(id: @values[:connection_id]).delete_all
        Result.new(message: disconnected.zero? ? "That connection is not one of yours" : nil)
      end
    end
  end
end
