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

    deployer_method :analyze
    deployer_method :deploy_cookbook

    def build_cookbook(cookbook)
      DreamOps.ui.info "...Building cookbook [#{cookbook[:name]}]"
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

    # The cleanup hook is defined by subclasses and is called by the CLI.
    def deploy(*args)
      cookbooks_to_build = analyze(args)

      # Build each unique cookbook once in case it's used by more than one app
      cookbooks_to_build.each do |cookbook|
        build_cookbook(cookbook)
        deploy_cookbook(cookbook)
      end
      cleanup_cookbooks(cookbooks_to_build)
    end
  end
end