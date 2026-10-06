module HubKernel
  module Mcp
    class Engine < ::Rails::Engine
      isolate_namespace HubKernel::Mcp
    end
  end
end
