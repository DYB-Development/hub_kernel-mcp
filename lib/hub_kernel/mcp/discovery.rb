require "action_dispatch"

module HubKernel
  module Mcp
    Discovery = ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        get "oauth-protected-resource(/*resource)", to: "hub_kernel/mcp/discovery#resource"
      end
    end
  end
end
