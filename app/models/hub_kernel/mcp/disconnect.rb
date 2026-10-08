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
        Connection.of(@person).where(id: @values[:connection_id]).delete_all
        Result.new(message: nil)
      end
    end
  end
end
