Rails.application.routes.draw do
  mount HubKernel::Mcp::Engine => "/mcp"
  mount HubKernel::Mcp::Discovery => "/.well-known"
end
