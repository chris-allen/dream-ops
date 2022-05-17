module DreamOps
  class SoloInitializer < BaseInitializer
    def analyze(targets)
      @ssh_opts = "-i #{DreamOps.ssh_key} -o LogLevel=ERROR -o StrictHostKeyChecking=no"
      @q_all = "> /dev/null 2>&1"
      @q_stdout = "> /dev/null"

      result = []

      targets.each do |target|
        # Validate SSH creds
        if DreamOps.ssh_key.empty?
          __bail_with_fatal_error(NoSshKeyError.new())
        end
        hostname = `ssh #{@ssh_opts} #{target} sudo hostname 2>&1`.chomp
        if ! $?.success?
          __bail_with_fatal_error(InvalidSshKeyError.new(target, hostname))
        end

        DreamOps.ui.info "Target: #{hostname}"

        target_result = { host: target }

        target_result[:chefdk_installed] = system("ssh #{@ssh_opts} #{target} which chef #{@q_all}")
        DreamOps.ui.info "--- Chef Workstation Installed: #{target_result[:chefdk_installed]}"

        target_result[:solo_json_exists] = system("ssh #{@ssh_opts} #{target} stat /var/chef/chef.json #{@q_all}")
        DreamOps.ui.info "--- Valid chef.json: #{target_result[:solo_json_exists]}"

        target_result[:setup_role_exists] = system("ssh #{@ssh_opts} #{target} stat /var/chef/roles/setup.json #{@q_all}")
        DreamOps.ui.info "--- Valid role[setup]: #{target_result[:setup_role_exists]}"

        target_result[:deploy_role_exists] = system("ssh #{@ssh_opts} #{target} stat /var/chef/roles/deploy.json #{@q_all}")
        DreamOps.ui.info "--- Valid role[deploy]: #{target_result[:deploy_role_exists]}"

        result << target_result
      end

      return result
    end

    def init_target(target, dryrun)
      # Install ChefWorkstation if not already
      if !target[:chefdk_installed]
        if dryrun
          DreamOps.ui.warn "...WOULD Install Chef Workstation [target=\"#{target[:host]}\"]"
        else
          DreamOps.ui.warn "...Installing Chef Workstation [target=\"#{target[:host]}\"]"

          # Install GPG key
          gpg_key_url = "https://packages.chef.io/chef.asc"
          gpg_key_path = "/usr/share/keyrings/chef-archive-keyring.gpg"
          `ssh #{@ssh_opts} #{target[:host]} "curl -sL #{gpg_key_url} | gpg --dearmor | sudo tee #{gpg_key_path} #{@q_all}"`

          # Add apt repo
          `ssh #{@ssh_opts} #{target[:host]} "echo \"deb [signed-by=#{gpg_key_path}] https://packages.chef.io/repos/apt/stable focal main\" > /tmp/chef-stable.list" #{@q_all}`
          `ssh #{@ssh_opts} #{target[:host]} "sudo mv /tmp/chef-stable.list /etc/apt/sources.list.d/" #{@q_all}`
          `ssh #{@ssh_opts} #{target[:host]} "sudo apt update" #{@q_all}`

          # Install the package
          if !system("ssh #{@ssh_opts} #{target[:host]} \"sudo apt install -y -q chef-workstation\" #{@q_all}")
            __bail_with_fatal_error(ChefWorkstationFailedError.new(target, gpg_key_url))
          end
        end
      end

      if !dryrun
        `ssh #{@ssh_opts} #{target[:host]} sudo mkdir -p /var/chef/roles`
      end

      # Create empty json file for chef-solo
      if !target[:solo_json_exists]
        json_path = "/var/chef/chef.json"
        if dryrun
          DreamOps.ui.warn "...WOULD Create boilerplate #{json_path} [target=\"#{target[:host]}\"]"
        else
          DreamOps.ui.warn "...Creating boilerplate #{json_path} [target=\"#{target[:host]}\"]"
          `ssh #{@ssh_opts} #{target[:host]} "echo '{\n  \\"run_list\\": []\n}' | sudo tee -a #{json_path}"`
        end
      end

      # Create setup role with empty run_list for chef-solo
      if !target[:setup_role_exists]
        setup_path = "/var/chef/roles/setup.json"
        if dryrun
          DreamOps.ui.warn "...WOULD Create boilerplate #{setup_path} [target=\"#{target[:host]}\"]"
        else
          DreamOps.ui.warn "...Creating boilerplate #{setup_path} [target=\"#{target[:host]}\"]"
          role_contents = [
            '{',
            '  \"name\": \"setup\",',
            '  \"json_class\": \"Chef::Role\",',
            '  \"description\": \"This role is intended for use when cookbook changes are detected\",',
            '  \"chef_type\": \"role\",',
            '  \"run_list\": []',
            '}',
          ].join("\n")
          `ssh #{@ssh_opts} #{target[:host]} "echo '#{role_contents}' | sudo tee -a #{setup_path}"`
        end
      end

      # Create deploy role with empty run_list for chef-solo
      if !target[:deploy_role_exists]
        deploy_path = "/var/chef/roles/deploy.json"
        if dryrun
          DreamOps.ui.warn "...WOULD Create boilerplate #{deploy_path} [target=\"#{target[:host]}\"]"
        else
          DreamOps.ui.warn "...Creating boilerplate #{deploy_path} [target=\"#{target[:host]}\"]"
          role_contents = [
            '{',
            '  \"name\": \"deploy\",',
            '  \"json_class\": \"Chef::Role\",',
            '  \"description\": \"This role is intended for use when code changes\",',
            '  \"chef_type\": \"role\",',
            '  \"run_list\": []',
            '}',
          ].join("\n")
          `ssh #{@ssh_opts} #{target[:host]} "echo '#{role_contents}' | sudo tee -a #{deploy_path}"`
        end
      end
    end
  end
end
