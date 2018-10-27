# XXX: work around logger spam from hashie
# https://github.com/intridea/hashie/issues/394
begin
  require "hashie"
  require "hashie/logger"
  Hashie.logger = Logger.new(nil)
rescue LoadError
  # intentionally left blank
end

require "berkshelf"
require "thor"

module DreamOps

  require_relative "dream-ops/version"
  require_relative "dream-ops/errors"

  module Mixin
    autoload :Logging,        "dream-ops/mixin/logging"
  end

  autoload :Shell,            "dream-ops/shell"

  autoload :BaseFormatter,    "dream-ops/formatters/base"
  autoload :HumanFormatter,   "dream-ops/formatters/human"
  # autoload :JsonFormatter,    "dream-ops/formatters/json"
  # autoload :NullFormatter,    "dream-ops/formatters/null"

  autoload :BaseDeployer,     "dream-ops/deployment/base"
  autoload :OpsWorksDeployer, "dream-ops/deployment/opsworks"
  autoload :SoloDeployer,     "dream-ops/deployment/solo"
  autoload :BaseInitializer,  "dream-ops/init/base"
  autoload :SoloInitializer,  "dream-ops/init/solo"

  class << self
    include Mixin::Logging

    # @return [DreamOps::Shell]
    def ui
      @ui ||= DreamOps::Shell.new
    end

    # Get the appropriate Formatter object based on the formatter
    # classes that have been registered.
    #
    # @return [~Formatter]
    def formatter
      @formatter ||= HumanFormatter.new
    end

    # Specify the format for output
    #
    # @param [#to_sym] format_id
    #   the ID of the registered formatter to use
    #
    # @example DreamOps.set_format :json
    #
    # @return [~Formatter]
    def set_format(name)
      id = name.to_s.capitalize
      @formatter = DreamOps.const_get("#{id}Formatter").new
    end

    # Get path for the SSH key
    #
    # @return [~String]
    def ssh_key
      @ssh_key ||= nil
    end

    # Specify path to use for the SSH key
    #
    # @return [~String]
    def set_ssh_key(key)
      @ssh_key = key
    end

    # Get whether to always run setup
    #
    # @return [~boolean]
    def force_setup
      @force_setup ||= false
    end

    # Specify whether to always run setup
    #
    # @return [~boolean]
    def set_force_setup(force)
      @force_setup = force
    end
  end
end

require_relative "dream-ops/cli"
require_relative "dream-ops/logger"

DreamOps.logger.level  = Logger::WARN
