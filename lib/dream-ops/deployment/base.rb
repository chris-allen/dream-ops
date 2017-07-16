require "berkshelf"
require "dream-ops/utils/zip"
require 'fileutils'

module DreamOps
  class BaseDeployer
    class << self
      #
      # @macro deployer_method
      #   @method $1(*args)
      #     Create a deployer method for the declaration
      #
      def deployer_method(name)
        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{name}(*args)
            raise AbstractFunction,
              "##{name} must be implemented on \#{self.class.name}!"
          end
        EOH
      end
    end

    # These MUST be implemented by subclasses
    deployer_method :analyze
    deployer_method :deploy_cookbook
    deployer_method :deploy_target

    # It may turn out that cookbook building will be different for different
    # deployments, but for now all deployments build them the same way.
    def build_cookbook(cookbook)
      berksfile = Berkshelf::Berksfile.from_file(File.join(cookbook[:path], "Berksfile"))
      berksfile.vendor("berks-cookbooks")

      File.open("berks-cookbooks/Berksfile", 'w') { |file|
        file.write("source \"https://supermarket.chef.io\"\n\n")
        file.write("cookbook \"#{cookbook[:name]}\", path: \"./#{cookbook[:name]}\"")
      }
      zf = ZipFileGenerator.new("berks-cookbooks", cookbook[:cookbook_key])
      zf.write
    end

    def cleanup_cookbooks(cookbooks)
      cookbooks.each do |cookbook|
        File.delete(cookbook[:cookbook_key])
        FileUtils.remove_dir("berks-cookbooks")
      end
    end

    def deploy(*args)
      # Find unique cookbooks and deploy targets
      result = analyze(args)

      # Build each unique cookbook once in case it's used by more than one app
      result[:cookbooks].each do |cookbook|
        DreamOps.ui.info "...Building cookbook [#{cookbook[:name]}]"
        build_cookbook(cookbook)

        DreamOps.ui.info "...Deploying cookbook [#{cookbook[:name]}]"
        deploy_cookbook(cookbook)
      end
      cleanup_cookbooks(result[:cookbooks])

      # Update cookbooks if needed and deploy to all targets
      deploy_success = true
      deploy_threads = []
      result[:deploy_targets].each do |target|
        deploy_threads << Thread.new { deploy_target(target, result[:cookbooks]) }
      end
      deploy_threads.each do |t|
        begin
          t.join
        rescue DreamOps::FatalDeployError
          deploy_success = deploy_success && false
        end
      end

      exit(1) if !deploy_success
    end
  end
end