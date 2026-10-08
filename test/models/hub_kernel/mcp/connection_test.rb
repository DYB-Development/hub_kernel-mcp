require "test_helper"

class HubKernel::Mcp::ConnectionTest < ActiveSupport::TestCase
  setup { @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ]) }

  test "an issued access token is kept only as its digest, holding who it acts for and which client holds it" do
    token = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client).access_token

    stored = HubKernel::Mcp::Connection.sole
    assert_equal [ Digest::SHA256.hexdigest(token), Person.new("sam"), @client ], [ stored.token_digest, stored.person, stored.client ]
  end

  test "an unexpired access token gives the person it acts for" do
    token = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client).access_token

    assert_equal Person.new("sam"), HubKernel::Mcp::Connection.person_for(token)
  end

  test "an expired access token gives no person" do
    token = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client).access_token
    travel 1.hour + 1.second

    assert_nil HubKernel::Mcp::Connection.person_for(token)
  end

  test "an unknown access token gives no person" do
    HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)

    assert_nil HubKernel::Mcp::Connection.person_for("unknown")
  end

  test "a refresh token renews the connection with a new pair of tokens and stops working itself" do
    tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)

    renewed = HubKernel::Mcp::Connection.refresh(tokens.refresh_token, client: @client)

    assert_equal [ Person.new("sam"), nil ], [ HubKernel::Mcp::Connection.person_for(renewed.access_token), HubKernel::Mcp::Connection.refresh(tokens.refresh_token, client: @client) ]
  end

  test "a refresh token posted by another client gives nothing" do
    tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)
    other = HubKernel::Mcp::Client.create!(name: "Other", redirect_uris: [ "https://claude.ai/callback" ])

    assert_nil HubKernel::Mcp::Connection.refresh(tokens.refresh_token, client: other)
  end

  test "a refresh token unused for ninety days gives nothing" do
    tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)
    travel 90.days + 1.second

    assert_nil HubKernel::Mcp::Connection.refresh(tokens.refresh_token, client: @client)
  end

  test "looking up a person by an access token records when the connection was last used" do
    tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)
    travel 30.minutes

    HubKernel::Mcp::Connection.person_for(tokens.access_token)

    assert_equal Time.current, HubKernel::Mcp::Connection.sole.last_used_at
  end

  test "a person's connections hold only the ones acting for that person" do
    HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)
    HubKernel::Mcp::Connection.issue(person: Person.new("alex"), client: @client)

    assert_equal [ Person.new("sam") ], HubKernel::Mcp::Connection.of(Person.new("sam")).map(&:person)
  end
end
