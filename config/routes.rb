HubKernel::Mcp::Engine.routes.draw do
  post "/", to: "messages#create"
  get "/", to: "messages#refuse_get"
  post "register", to: "registrations#create"
  get "authorize", to: "authorizations#new"
  post "authorize", to: "authorizations#create"
end
