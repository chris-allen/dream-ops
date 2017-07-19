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

  class NoRunningInstancesError < DreamOpsError
    set_status_code(10)

    def initialize(stack)
      @stack = stack
    end

    def to_s
      "Stack \"#{@stack.name}\" has no running instances."
    end
  end

  class OpsWorksCommandFailedError < DreamOpsError
    set_status_code(11)

    def initialize(stack, deployment_id, command)
      @stack         = stack
      @deployment_id = deployment_id
      @command       = command
    end

    def to_s
      [
        "Stack \"#{@stack.name}\" failed running command '#{@command}'. To view the failure log, visit:",
        "",
        "https://console.aws.amazon.com/opsworks/home?region=#{@stack.region}#/stack/#{@stack.stack_id}/deployments/#{@deployment_id}",
      ].join("\n")
    end

    alias_method :message, :to_s
  end
end