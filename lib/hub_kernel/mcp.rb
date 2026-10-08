require "hub_kernel-interface"
require "hub_kernel/mcp/version"
require "hub_kernel/mcp/engine"
require "hub_kernel/mcp/discovery"

module HubKernel
  module Mcp
    UnservableHubError = HubKernel::Interface::UnservableHubError

    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method
    mattr_accessor :browser_controller
    mattr_accessor :sign_in_method
    mattr_accessor :browser_person_method
    mattr_accessor :browser_layout

    BROWSER_SETTINGS = %i[browser_controller sign_in_method browser_person_method browser_layout].freeze

    def self.check!
      problems = shared_problems + doubled_underscores + unlisted_characters + long_names + unset_browser_settings
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

    def self.long_names
      tool_names.select { |name| name.length > 64 }.map { |name| "The tool #{name} is longer than 64 characters" }
    end

    def self.unset_browser_settings
      BROWSER_SETTINGS.reject { |setting| public_send(setting) }.map { |setting| "HubKernel::Mcp.#{setting} is not set" }
    end

    def self.tool_names
      HubKernel::Interface.served.select { |_name, hub| hub.respond_to?(:exposures) }.flat_map do |served_name, hub|
        hub.exposures.map { |exposure| "#{served_name}__#{exposure.name}" }
      end
    end

    private_class_method :shared_problems, :doubled_underscores, :unlisted_characters, :long_names, :unset_browser_settings, :tool_names
  end
end
