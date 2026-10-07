require "hub_kernel-interface"
require "hub_kernel/mcp/version"
require "hub_kernel/mcp/engine"

module HubKernel
  module Mcp
    UnservableHubError = HubKernel::Interface::UnservableHubError

    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method

    def self.check! = HubKernel::Interface.check!
  end
end
