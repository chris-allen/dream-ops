
require "thor"

module Dreamify

  require_relative "dreamify/version"
  require_relative "dreamify/errors"

  autoload :Shell,      "dreamify/shell"

  autoload :BaseFormatter,  "dreamify/formatters/base"
  autoload :HumanFormatter, "dreamify/formatters/human"
  # autoload :JsonFormatter,  "dreamify/formatters/json"
  # autoload :NullFormatter,  "dreamify/formatters/null"

  class << self
    # @return [Dreamify::Shell]
    def ui
      @ui ||= Dreamify::Shell.new
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
    # @example Dreamify.set_format :json
    #
    # @return [~Formatter]
    def set_format(name)
      id = name.to_s.capitalize
      @formatter = Dreamify.const_get("#{id}Formatter").new
    end
  end
end

require_relative "dreamify/cli"