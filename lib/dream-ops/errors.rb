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
  end

  class NoSshKeyError < DreamOpsError
    set_status_code(12)

    def to_s
      "You mush specify a SSH key for authentication."
    end
  end

  class InvalidSshKeyError < DreamOpsError
    set_status_code(13)

    def initialize(target, output)
      @target = target
      @output = output
    end

    def to_s
      [
        "Failed to communicate with '#{@target}' over ssh:",
        "",
        @output,
    ].join("\n")
    end
  end

  class ChefDKNotInstalledError < DreamOpsError
    set_status_code(14)

    def initialize(target)
      @target = target
    end

    def to_s
      [
        "ChefDK not installed on target \"#{@target}\". To initialize chef-solo, run:",
        "",
        "dream init solo -t #{@target} -i #{DreamOps.ssh_key}",
      ].join("\n")
    end
  end

  class ChefDKFailedError < DreamOpsError
    set_status_code(15)

    def initialize(target, wget_url)
      @target   = target
      @wget_url = wget_url
    end

    def to_s
      [
        "Target \"#{@target}\" failed installing ChefDK from:",
        "",
        @wget_url,
      ].join("\n")
    end
  end

  class ChefSoloFailedError < DreamOpsError
    set_status_code(16)

    def initialize(target, log_path)
      @target   = target
      @log_path = log_path
    end

    def to_s
      [
        "Target \"#{@target}\" failed running chef-solo. The failure log is located at:",
        "",
        @log_path,
      ].join("\n")
    end
  end

  class ChefJsonNotFoundError < DreamOpsError
    set_status_code(17)

    def initialize(target)
      @target = target
    end

    def to_s
      [
        "Could not find /var/chef/chef.json \"#{@target}\". To initialize with an empty runlist, run:",
        "",
        "dream init solo -t #{@target} -i #{DreamOps.ssh_key}",
      ].join("\n")
    end
  end

  class RoleNotFoundError < DreamOpsError
    set_status_code(18)

    def initialize(target, role)
      @target = target
      @role   = role
    end

    def to_s
      [
        "Could not find /var/chef/roles/#{@role}.json \"#{@target}\". To initialize with an empty runlist, run:",
        "",
        "dream init solo -t #{@target} -i #{DreamOps.ssh_key}",
      ].join("\n")
    end
  end

  class GitNotInstalledError < DreamOpsError
    set_status_code(19)

    def to_s
      "Unabled to find git in your PATH."
    end
  end
end
