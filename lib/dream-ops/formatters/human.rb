module DreamOps
  class HumanFormatter < BaseFormatter
    # Output the version of DreamOps
    def version
      DreamOps.ui.info "Dream Ops v#{DreamOps::VERSION}"
    end

    # @param [DreamOps::Dependency] dependency
    def fetch(dependency)
      DreamOps.ui.info "Fetching '#{dependency.name}' from #{dependency.location}"
    end

    # Output a Cookbook installation message using {DreamOps.ui}
    #
    # @param [Source] source
    #   the source the dependency is being downloaded from
    # @param [RemoteCookbook] cookbook
    #   the cookbook to be downloaded
    def install(source, cookbook)
      message = "Installing #{cookbook.name} (#{cookbook.version})"

      if source.type == :chef_repo
        message << " from #{cookbook.location_path}"
      elsif !source.default?
        message << " from #{source}"
        message << " ([#{cookbook.location_type}] #{cookbook.location_path})"
      end

      DreamOps.ui.info(message)
    end

    # Output a Cookbook use message using {DreamOps.ui}
    #
    # @param [Dependency] dependency
    def use(dependency)
      message =  "Using #{dependency.name} (#{dependency.locked_version})"
      message << " from #{dependency.location}" if dependency.location
      DreamOps.ui.info(message)
    end

    # Output a Cookbook upload message using {DreamOps.ui}
    #
    # @param [DreamOps::CachedCookbook] cookbook
    # @param [Ridley::Connection] conn
    def uploaded(cookbook, conn)
      DreamOps.ui.info "Uploaded #{cookbook.cookbook_name} (#{cookbook.version}) to: '#{conn.server_url}'"
    end

    # Output a Cookbook skip message using {DreamOps.ui}
    #
    # @param [DreamOps::CachedCookbook] cookbook
    # @param [Ridley::Connection] conn
    def skipping(cookbook, conn)
      DreamOps.ui.info "Skipping #{cookbook.cookbook_name} (#{cookbook.version}) (frozen)"
    end

    # Output a list of outdated cookbooks and the most recent version
    # using {DreamOps.ui}
    #
    # @param [Hash] hash
    #   the list of outdated cookbooks in the format
    #   { 'cookbook' => { 'supermarket.chef.io' => #<Cookbook> } }
    def outdated(hash)
      if hash.empty?
        DreamOps.ui.info("All cookbooks up to date!")
      else
        DreamOps.ui.info("The following cookbooks have newer versions:")

        hash.each do |name, info|
          info["remote"].each do |remote_source, remote_version|
            out = "  * #{name} (#{info['local']} => #{remote_version})"

            unless remote_source.default?
              out << " [#{remote_source.uri}]"
            end

            DreamOps.ui.info(out)
          end
        end
      end
    end

    # Output a Cookbook package message using {DreamOps.ui}
    #
    # @param [String] destination
    def package(destination)
      DreamOps.ui.info "Cookbook(s) packaged to #{destination}"
    end

    # Output the important information about a cookbook using {DreamOps.ui}.
    #
    # @param [CachedCookbook] cookbook
    def info(cookbook)
      DreamOps.ui.info(cookbook.pretty_print)
    end

    # Output a list of cookbooks using {DreamOps.ui}
    #
    # @param [Array<Dependency>] list
    def list(dependencies)
      DreamOps.ui.info "Cookbooks installed by your Berksfile:"
      dependencies.each do |dependency|
        out =  "  * #{dependency}"
        out << " from #{dependency.location}" if dependency.location
        DreamOps.ui.info(out)
      end
    end

    # Ouput Cookbook search results using {DreamOps.ui}
    #
    # @param [Array<APIClient::RemoteCookbook>] results
    def search(results)
      results.sort_by(&:name).each do |remote_cookbook|
        DreamOps.ui.info "#{remote_cookbook.name} (#{remote_cookbook.version})"
      end
    end

    # Output Cookbook path using {DreamOps.ui}
    #
    # @param [CachedCookbook] cookbook
    def show(cookbook)
      path = File.expand_path(cookbook.path)
      DreamOps.ui.info(path)
    end

    # Output Cookbook vendor info message using {DreamOps.ui}
    #
    # @param [CachedCookbook] cookbook
    # @param [String] destination
    def vendor(cookbook, destination)
      cookbook_destination = File.join(destination, cookbook.cookbook_name)
      DreamOps.ui.info "Vendoring #{cookbook.cookbook_name} (#{cookbook.version}) to #{cookbook_destination}"
    end

    # Output a generic message using {DreamOps.ui}
    #
    # @param [String] message
    def msg(message)
      DreamOps.ui.info message
    end

    # Output an error message using {DreamOps.ui}
    #
    # @param [String] message
    def error(message)
      DreamOps.ui.error message
    end

    # Output a warning message using {DreamOps.ui}
    #
    # @param [String] message
    def warn(message)
      DreamOps.ui.warn message
    end

    # Output a deprecation warning
    #
    # @param [String] message
    def deprecation(message)
      DreamOps.ui.info "DEPRECATED: #{message}"
    end
  end
end