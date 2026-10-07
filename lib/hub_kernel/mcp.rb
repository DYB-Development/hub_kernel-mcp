require "hub_kernel-interface"
require "hub_kernel/mcp/version"
require "hub_kernel/mcp/engine"

module HubKernel
  module Mcp
    UnservableHubError = HubKernel::Interface::UnservableHubError

    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method

    def self.check!
      problems = shared_problems + doubled_underscores + unlisted_characters
      raise UnservableHubError, problems.join("\n") if problems.any?
    end

    def self.shared_problems
      HubKernel::Interface.check!
      []
    rescue UnservableHubError => error
      error.message.split("\n")
    end

    def self.doubled_underscores
      HubKernel::Interface.served.select { |name, _hub| name.include?("__") }.map do |name, hub|
        "#{hub.name} is served at #{name}, which holds two underscores in a row"
      end
    end

    def self.unlisted_characters
      tool_names.grep_v(/\A[A-Za-z0-9_-]*\z/).map do |name|
        "The tool #{name} holds a character other than a letter, a digit, an underscore or a hyphen"
      end
    end

    def self.tool_names
      HubKernel::Interface.served.select { |_name, hub| hub.respond_to?(:exposures) }.flat_map do |served_name, hub|
        hub.exposures.map { |exposure| "#{served_name}__#{exposure.name}" }
      end
    end

    private_class_method :shared_problems, :doubled_underscores, :unlisted_characters, :tool_names
  end
end
