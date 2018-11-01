module DreamOps
  class BaseInitializer
    class << self
      #
      # @macro initiailizer_method
      #   @method $1(*args)
      #     Create a initiailizer method for the declaration
      #
      def initiailizer_method(name)
        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{name}(*args)
            raise AbstractFunction,
              "##{name} must be implemented on \#{self.class.name}!"
          end
        EOH
      end
    end

    # This method MUST be implemented by subclasses.
    #
    # @return [Array]
    #   an array of configuration for each target
    #
    #   Example:
    #     [
    #       {
    #         :host => "ubuntu@example.com"
    #         :chefdk_installed => false,
    #         :solo_json_exists => false,
    #         :setup_role_exists => true,
    #         :deploy_role_exists => true
    #       }
    #     ]
    initiailizer_method :analyze

    # This method MUST be implemented by subclasses.
    #
    # @param [String] target
    #   a target host
    initiailizer_method :init_target

    def __bail_with_fatal_error(ex)
      raise ex
      Thread.exit
    end

    def init(*args, dryrun)
      targets = analyze(args)

      # Update cookbooks if needed and deploy to all targets
      deploy_success = true
      deploy_threads = []
      targets.each do |target|
        deploy_threads << Thread.new { init_target(target, dryrun) }
      end
      deploy_threads.each do |t|
        begin
          t.join
        rescue DreamOps::DreamOpsError
          DreamOps.ui.error "#{$!}"
          deploy_success = deploy_success && false
        end
      end

      # If ANY deploy threads failed, exit with failure
      exit(1) if !deploy_success
    end
  end
end
