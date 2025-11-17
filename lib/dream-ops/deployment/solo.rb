require 'securerandom'
require 'timeout'

module DreamOps
  class SoloDeployer < BaseDeployer
    def __cookbook_in_array(cb, cookbooks)
      return cookbooks.any? {|c| c[:name] == cb[:name]}
    end

    def __cookbook_was_updated(target, cookbooks)
      return cookbooks.any? {|c| c[:targets].include? target }
    end

    def __wait_for_pid(pid)
      while true do
        begin
          Timeout.timeout(5) do
            Process.wait pid
          end
          print "\b"
          return $?.exitstatus == 0
        rescue Timeout::Error
          print "\r#{@@spinner.next}"
        end
      end
    end

    # Analyze the SSH hosts for deployment
    #
    # @return [Hash]
    #   a hash containing cookbooks that need to be built/updated
    #   and deploy targets
    #
    #   Example:
    #     {
    #       :cookbooks => [
    #         {
    #           :bucket => "chef-app",
    #           :cookbook_filename => "chef-app-dev.tar.gz",
    #           :sha_filename => "chef-app-dev_SHA.txt",
    #           :name => "chef-app",
    #           :path => "./chef",
    #           :local_sha => "7bfa19491170563f422a321c144800f4435323b1",
    #           :targets => [ "ubuntu@example.com" ]
    #         }
    #       ],
    #       deploy_targets: [
    #         {
    #           :host => "ubuntu@example.com"
    #           :remote_sha => ""
    #         }
    #       ]
    #     }
    def analyze(targets)
      @ssh_opts = "-i #{DreamOps.ssh_key} -o LogLevel=ERROR -o StrictHostKeyChecking=no"
      @q_all = "> /dev/null 2>&1"
      @q_stdout = "> /dev/null"

      # Collect and print target info
      result = { cookbooks: [], deploy_targets: [] }
      targets.each do |target|
        target_result = analyze_target(target)
        # Add the target to the deploy targets
        result[:deploy_targets] << target_result[:deploy_target]
        # Determine whether the cookbook needs to be built
        cbook = target_result[:cookbook]
        if !cbook.nil? && !cbook[:local_sha].nil?
          # We only build the cookbook if we don't have this version remotely
          if target_result[:deploy_target][:remote_sha] != cbook[:local_sha]
            # Don't build the same destination cookbook more than once
            if !__cookbook_in_array(cbook, result[:cookbooks])
              cbook[:targets] = [target]
              result[:cookbooks] << cbook
            else
              # Add target to be deployed to
              cbook_index = result[:cookbooks].index { |c| c[:name] == cbook[:name] }
              result[:cookbooks][cbook_index][:targets] << target
            end
          end
        end
      end

      return result
    end

    def analyze_target(target)
      # Validate SSH creds
      if DreamOps.ssh_key.empty?
        __bail_with_fatal_error(NoSshKeyError.new())
      end
      hostname = `ssh #{@ssh_opts} #{target} sudo hostname 2>&1`.chomp
      if ! $?.success?
        __bail_with_fatal_error(InvalidSshKeyError.new(target, hostname))
      end

      DreamOps.ui.info "Target: #{hostname}"

      result = { host: target }
      cookbook = { }
      cookbooks = __get_cookbook_paths()

      # For now we only handle if we find one cookbook
      if cookbooks.length == 1
        path = cookbooks[0]
        loader = Chef::Cookbook::CookbookVersionLoader.new(path)
        loader.load!
        cookbook_version = loader.cookbook_version
        metadata = cookbook_version.metadata

        cookbook[:sha_filename] = "#{metadata.name}_SHA.txt"
        cookbook[:cookbook_filename] = "#{metadata.name}.tar.gz"
        cookbook[:name] = metadata.name
        cookbook[:path] = path
        cookbook[:local_sha] = `git log --pretty=%H -1 #{cookbook[:path]}`.chomp

        `ssh #{@ssh_opts} #{target} sudo mkdir -p /var/chef/cookbooks`

        if system("ssh #{@ssh_opts} #{target} stat /var/chef/#{cookbook[:sha_filename]} #{@q_all}")
          result[:remote_sha] = `ssh #{@ssh_opts} #{target} cat /var/chef/#{cookbook[:sha_filename]}`.chomp
        else
          result[:remote_sha] = ""
        end
      elsif cookbooks.length > 1
        DreamOps.ui.warn "Found more than one cookbook at paths #{cookbooks}.  Skipping build."
        cookbook[:name] = "???"
      else
        DreamOps.ui.warn "No cookbook found"
        cookbook[:name] = "???"
      end

      suffix = if cookbook[:local_sha] != result[:remote_sha] then "(outdated)" else "(up to date)" end
      DreamOps.ui.info "--- Cookbook: #{cookbook[:name]} #{suffix}"

      return { deploy_target: result, cookbook: cookbook }
    end

    # Deploys cookbook to server
    def deploy_cookbook(cookbook)
      cookbook[:targets].each do |target|
        if system("scp #{@ssh_opts} #{cookbook[:cookbook_filename]} #{target}:/tmp #{@q_all}")
          `ssh #{@ssh_opts} #{target} sudo rm -rf /var/chef/cookbooks/* #{@q_all}`
          `ssh #{@ssh_opts} #{target} sudo tar -xzvf /tmp/#{cookbook[:cookbook_filename]} -C /var/chef/cookbooks #{@q_all}`
          `ssh #{@ssh_opts} #{target} sudo rm -rf /tmp/#{cookbook[:cookbook_filename]} #{@q_all}`
        else
          DreamOps.ui.error "Failed to copy cookbook to host '#{target}'"
        end

        if !system(
          "ssh #{@ssh_opts} #{target} "+
          "\"echo '#{cookbook[:local_sha]}' | sudo tee /var/chef/#{cookbook[:sha_filename]}\" #{@q_all}"
        )
          DreamOps.ui.error "Failed to update remote cookbook sha"
        end
      end
    end

    def run_chef_role(target, role)
      if !system("ssh #{@ssh_opts} #{target[:host]} stat /var/log/chef #{@q_all}")
        `ssh #{@ssh_opts} #{target[:host]} sudo mkdir -p /var/log/chef`
      end

      uuid = SecureRandom.uuid

      chef_cmd = "cinc-solo"
      if !system("ssh #{@ssh_opts} #{target[:host]} which cinc-solo #{@q_all}")
        chef_cmd = "chef-solo --chef-license accept"
      end

      pid = fork do
        if ! system(
          "ssh #{@ssh_opts} #{target[:host]} \"" +
            "set -o pipefail && " +
            "sudo #{chef_cmd} -j /var/chef/chef.json -o \"role[#{role}]\" 2>&1 | sudo tee /var/log/chef/#{uuid}.log #{@q_all}\""
        )
          exit 1
        end
        exit 0
      end

      if !__wait_for_pid(pid)
        __bail_with_fatal_error(ChefSoloFailedError.new(target[:host], "/var/log/chef/#{uuid}.log"))
      end
    end

    def deploy_target(target, cookbooks)
      # Bail if chef-solo is not installed
      if !system("ssh #{@ssh_opts} #{target[:host]} which chef-solo #{@q_all}")
        __bail_with_fatal_error(ChefSoloNotInstalledError.new(target[:host]))
      end

      # Bail if chef.json doesn't exist
      if !system("ssh #{@ssh_opts} #{target[:host]} stat /var/chef/chef.json #{@q_all}")
        __bail_with_fatal_error(ChefJsonNotFoundError.new(target[:host]))
      end

      # Bail if setup.json doesn't exist
      if !system("ssh #{@ssh_opts} #{target[:host]} stat /var/chef/roles/setup.json #{@q_all}")
        __bail_with_fatal_error(RoleNotFoundError.new(target[:host], "setup"))
      end

      # Bail if deploy.json doesn't exist
      if !system("ssh #{@ssh_opts} #{target[:host]} stat /var/chef/roles/deploy.json #{@q_all}")
        __bail_with_fatal_error(RoleNotFoundError.new(target[:host], "deploy"))
      end

      # If this stack has a new cookbook, re-run the setup role
      if (
        __cookbook_was_updated(target[:host], cookbooks) ||
        DreamOps.force_setup
      )
        DreamOps.ui.info "...Running setup role [target=\"#{target[:host]}\"]"
        run_chef_role(target, "setup")
      end

      DreamOps.ui.info "...Running deploy role [target=\"#{target[:host]}\"]"
      run_chef_role(target, "deploy")
    end
  end
end
