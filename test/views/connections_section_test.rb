require "test_helper"

class ConnectionsSectionTest < ActionView::TestCase
  helper KeystoneUiHelper

  setup do
    travel_to Time.utc(2026, 10, 8, 9, 30)
    claude = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    other = HubKernel::Mcp::Client.create!(name: "Other", redirect_uris: [ "https://other.example/callback" ])
    @tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: claude)
    HubKernel::Mcp::Connection.issue(person: Person.new("alex"), client: other)
  end

  test "a person's connections are listed with the app's name, when it connected and when it was last used" do
    travel 20.minutes
    HubKernel::Mcp::Connection.person_for(@tokens.access_token)

    assert_equal [ "Claude Connected October 08, 2026 09:30 Last used October 08, 2026 09:50 Disconnect" ], section_for(Person.new("sam")).css("li").map { |item| item.text.squish }
  end

  test "a connection's Disconnect button sends its id to the section's address by PATCH" do
    form = section_for(Person.new("sam")).at_css("li form")

    assert_equal [ "/settings/connections", "patch", HubKernel::Mcp::Connection.of(Person.new("sam")).sole.id.to_s ], [ form["action"], form.at_css("input[name=_method]")["value"], form.at_css("input[name=connection_id]")["value"] ]
  end

  test "each connection is shown in its own keystone panel" do
    assert_equal [ "Disconnect" ], section_for(Person.new("sam")).css("li div.ks-panel button").map(&:text)
  end

  test "a connection's Disconnect button is keystone's danger button" do
    assert_equal [ "ks-button ks-button-danger ks-button-md" ], section_for(Person.new("sam")).css("li form button").map { |button| button["class"] }
  end

  test "a connection's app name is the title of a keystone section" do
    assert_equal [ "Claude" ], section_for(Person.new("sam")).css("li h2.ks-section-title").map(&:text)
  end

  private

  def section_for(person)
    Nokogiri::HTML.fragment(render(partial: "hub_kernel/mcp/connections", locals: { person: person, account: "acme", selection: {}, submit_url: "/settings/connections" }))
  end
end
