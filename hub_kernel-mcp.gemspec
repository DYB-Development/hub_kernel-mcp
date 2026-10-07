require_relative "lib/hub_kernel/mcp/version"

Gem::Specification.new do |spec|
  spec.name        = "hub_kernel-mcp"
  spec.version     = HubKernel::Mcp::VERSION
  spec.authors     = [ "tylercschneider" ]
  spec.email       = [ "tylercschneider@gmail.com" ]
  spec.homepage    = "https://github.com/DYB-Development/hub_kernel-mcp"
  spec.summary     = "Serves a hub_kernel hub's exposed methods as MCP tools."
  spec.description = "hub_kernel-mcp serves the methods every hub a host serves exposes as MCP tools at one address, with every call going through the host's sign-in, permission check and account scope."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "hub_kernel-interface", "~> 0.6"
end
