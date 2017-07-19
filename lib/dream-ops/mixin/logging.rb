module DreamOps
  module Mixin
    module Logging
      attr_writer :logger

      def logger
        @logger ||= DreamOps::Logger.new(STDOUT)
      end
      alias_method :log, :logger
    end
  end
end
