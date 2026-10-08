HubKernel::Mcp::Engine.routes.draw do
  post "/", to: "messages#create"
  get "/", to: "messages#refuse_get"
  post "register", to: "registrations#create"
end
