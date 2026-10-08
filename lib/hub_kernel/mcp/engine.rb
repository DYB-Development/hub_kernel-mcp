require "keystone_ui"
require "hub_kernel/mcp/challenge"

module HubKernel
  module Mcp
    class Engine < ::Rails::Engine
      isolate_namespace HubKernel::Mcp

      middleware.use HubKernel::Mcp::Challenge

      initializer "hub_kernel.mcp.tailwind" do
        KeystoneUi.configuration.tailwind_sources << root.join("app/views/**/*.erb").to_s
      end
    end
  end
end
