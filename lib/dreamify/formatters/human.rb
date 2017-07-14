module Dreamify
  class HumanFormatter < BaseFormatter
    # Output the version of Dreamify
    def version
      Dreamify.ui.info Dreamify::VERSION
    end

    # @param [Dreamify::Dependency] dependency
    def fetch(dependency)
      Dreamify.ui.info "Fetching '#{dependency.name}' from #{dependency.location}"
    end

    # Output a Cookbook installation message using {Dreamify.ui}
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

      Dreamify.ui.info(message)
    end

    # Output a Cookbook use message using {Dreamify.ui}
    #
    # @param [Dependency] dependency
    def use(dependency)
      message =  "Using #{dependency.name} (#{dependency.locked_version})"
      message << " from #{dependency.location}" if dependency.location
      Dreamify.ui.info(message)
    end

    # Output a Cookbook upload message using {Dreamify.ui}
    #
    # @param [Dreamify::CachedCookbook] cookbook
    # @param [Ridley::Connection] conn
    def uploaded(cookbook, conn)
      Dreamify.ui.info "Uploaded #{cookbook.cookbook_name} (#{cookbook.version}) to: '#{conn.server_url}'"
    end

    # Output a Cookbook skip message using {Dreamify.ui}
    #
    # @param [Dreamify::CachedCookbook] cookbook
    # @param [Ridley::Connection] conn
    def skipping(cookbook, conn)
      Dreamify.ui.info "Skipping #{cookbook.cookbook_name} (#{cookbook.version}) (frozen)"
    end

    # Output a list of outdated cookbooks and the most recent version
    # using {Dreamify.ui}
    #
    # @param [Hash] hash
    #   the list of outdated cookbooks in the format
    #   { 'cookbook' => { 'supermarket.chef.io' => #<Cookbook> } }
    def outdated(hash)
      if hash.empty?
        Dreamify.ui.info("All cookbooks up to date!")
      else
        Dreamify.ui.info("The following cookbooks have newer versions:")

        hash.each do |name, info|
          info["remote"].each do |remote_source, remote_version|
            out = "  * #{name} (#{info['local']} => #{remote_version})"

            unless remote_source.default?
              out << " [#{remote_source.uri}]"
            end

            Dreamify.ui.info(out)
          end
        end
      end
    end

    # Output a Cookbook package message using {Dreamify.ui}
    #
    # @param [String] destination
    def package(destination)
      Dreamify.ui.info "Cookbook(s) packaged to #{destination}"
    end

    # Output the important information about a cookbook using {Dreamify.ui}.
    #
    # @param [CachedCookbook] cookbook
    def info(cookbook)
      Dreamify.ui.info(cookbook.pretty_print)
    end

    # Output a list of cookbooks using {Dreamify.ui}
    #
    # @param [Array<Dependency>] list
    def list(dependencies)
      Dreamify.ui.info "Cookbooks installed by your Berksfile:"
      dependencies.each do |dependency|
        out =  "  * #{dependency}"
        out << " from #{dependency.location}" if dependency.location
        Dreamify.ui.info(out)
      end
    end

    # Ouput Cookbook search results using {Dreamify.ui}
    #
    # @param [Array<APIClient::RemoteCookbook>] results
    def search(results)
      results.sort_by(&:name).each do |remote_cookbook|
        Dreamify.ui.info "#{remote_cookbook.name} (#{remote_cookbook.version})"
      end
    end

    # Output Cookbook path using {Dreamify.ui}
    #
    # @param [CachedCookbook] cookbook
    def show(cookbook)
      path = File.expand_path(cookbook.path)
      Dreamify.ui.info(path)
    end

    # Output Cookbook vendor info message using {Dreamify.ui}
    #
    # @param [CachedCookbook] cookbook
    # @param [String] destination
    def vendor(cookbook, destination)
      cookbook_destination = File.join(destination, cookbook.cookbook_name)
      Dreamify.ui.info "Vendoring #{cookbook.cookbook_name} (#{cookbook.version}) to #{cookbook_destination}"
    end

    # Output a generic message using {Dreamify.ui}
    #
    # @param [String] message
    def msg(message)
      Dreamify.ui.info message
    end

    # Output an error message using {Dreamify.ui}
    #
    # @param [String] message
    def error(message)
      Dreamify.ui.error message
    end

    # Output a warning message using {Dreamify.ui}
    #
    # @param [String] message
    def warn(message)
      Dreamify.ui.warn message
    end

    # Output a deprecation warning
    #
    # @param [String] message
    def deprecation(message)
      Dreamify.ui.info "DEPRECATED: #{message}"
    end
  end
end