require "hub_kernel-interface"
require "hub_kernel/mcp/version"
require "hub_kernel/mcp/engine"

module HubKernel
  module Mcp
    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method
  end
end
