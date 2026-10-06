Rails.application.routes.draw do
  mount HubKernel::Mcp::Engine => "/mcp"
end
