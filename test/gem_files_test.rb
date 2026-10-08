require "test_helper"

class GemFilesTest < ActiveSupport::TestCase
  test "the packaged gem ships its info, install and develop agents" do
    files = Gem::Specification.load(File.expand_path("../hub_kernel-mcp.gemspec", __dir__)).files

    assert_equal %w[the_local/agents/hub_kernel-mcp-develop.md the_local/agents/hub_kernel-mcp-info.md the_local/agents/hub_kernel-mcp-install.md], files.grep(%r{\Athe_local/agents/}).sort
  end

  test "the packaged gem ships its migrations" do
    files = Gem::Specification.load(File.expand_path("../hub_kernel-mcp.gemspec", __dir__)).files

    assert_includes files, "db/migrate/20261007000000_create_hub_kernel_mcp_clients.rb"
  end

  test "the packaged gem depends on keystone_ui for the pages it shows a person" do
    dependencies = Gem::Specification.load(File.expand_path("../hub_kernel-mcp.gemspec", __dir__)).runtime_dependencies

    assert_includes dependencies.map(&:name), "keystone_ui"
  end
end
