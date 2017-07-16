module DreamOps
  class DreamOpsError < StandardError
    class << self
      # @param [Integer] code
      def set_status_code(code)
        define_method(:status_code) { code }
        define_singleton_method(:status_code) { code }
      end
    end

    alias_method :message, :to_s
  end

  class FatalDeployError < DreamOpsError; set_status_code(10); end
end