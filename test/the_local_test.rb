require "test_helper"
require "open3"

class TheLocalTest < ActiveSupport::TestCase
  test "the committed locals hold the_local's format" do
    output, status = Open3.capture2e("bin/rails", "the_local:check", chdir: File.expand_path("..", __dir__))

    assert status.success?, output
  end
end
