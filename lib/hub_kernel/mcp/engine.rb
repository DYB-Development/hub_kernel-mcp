require "hub_kernel/mcp/challenge"

module HubKernel
  module Mcp
    class Engine < ::Rails::Engine
      isolate_namespace HubKernel::Mcp

      middleware.use HubKernel::Mcp::Challenge
    end
  end
end
