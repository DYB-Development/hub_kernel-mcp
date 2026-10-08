require "test_helper"

class HubKernel::Mcp::DisconnectTest < ActiveSupport::TestCase
  setup do
    @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    @tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)
    @connection = HubKernel::Mcp::Connection.sole
  end

  test "a person who disconnects a connection stops its access and refresh tokens from working" do
    result = HubKernel::Mcp::Disconnect.new(person: Person.new("sam"), account: "acme", values: { connection_id: @connection.id.to_s }).call

    assert_equal [ true, nil, nil ], [ result.ok?, HubKernel::Mcp::Connection.person_for(@tokens.access_token), HubKernel::Mcp::Connection.refresh(@tokens.refresh_token, client: @client) ]
  end

  test "a person cannot disconnect a connection acting for someone else" do
    result = HubKernel::Mcp::Disconnect.new(person: Person.new("alex"), account: "acme", values: { connection_id: @connection.id.to_s }).call

    assert_equal [ false, "That connection is not one of yours", Person.new("sam") ], [ result.ok?, result.message, HubKernel::Mcp::Connection.person_for(@tokens.access_token) ]
  end
end
