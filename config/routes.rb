HubKernel::Mcp::Engine.routes.draw do
  post "/", to: "messages#create"
end
