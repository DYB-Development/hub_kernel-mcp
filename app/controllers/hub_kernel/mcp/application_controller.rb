module HubKernel
  module Mcp
    class ApplicationController < HubKernel::Mcp.browser_controller.constantize
      helper KeystoneUiHelper
    end
  end
end
