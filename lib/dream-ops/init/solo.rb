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

        target_result[:solo_installed] = system("ssh #{@ssh_opts} #{target} which chef-solo #{@q_all}")
        DreamOps.ui.info "--- Is chef-solo Installed: #{target_result[:solo_installed]}"

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
      # Install chef-solo if not available
      if !target[:solo_installed]
        if dryrun
          DreamOps.ui.warn "...WOULD Install chef-solo via CINC [target=\"#{target[:host]}\"]"
        else
          DreamOps.ui.warn "...Installing chef-solo via CINC [target=\"#{target[:host]}\"]"

          # Get ubuntu version
          ubuntu_ver = `ssh #{@ssh_opts} #{target[:host]} "awk 'BEGIN { FS = \\"=\\" } /DISTRIB_RELEASE/ { print \\$2 }' /etc/lsb-release"`.chomp

          # Download and install the package
          deb_file = "cinc_17.10.0-1_amd64.deb"
          cinc_url = "http://downloads.cinc.sh/files/stable/cinc/17.10.0/ubuntu/#{ubuntu_ver}/#{deb_file}"
          if system("ssh #{@ssh_opts} #{target[:host]} \"wget #{cinc_url} -P /tmp\" #{@q_all}")
            `ssh #{@ssh_opts} #{target[:host]} "sudo dpkg -i /tmp/#{deb_file}" #{@q_all}`
            `ssh #{@ssh_opts} #{target[:host]} "sudo rm /tmp/#{deb_file}" #{@q_all}`
          else
            __bail_with_fatal_error(ChefSoloFailedError.new(target, cinc_url))
          end
        end
      end

      if !dryrun
        `ssh #{@ssh_opts} #{target[:host]} sudo mkdir -p /var/chef/cookbooks`
        `ssh #{@ssh_opts} #{target[:host]} sudo mkdir -p /var/chef/roles`

        if system("ssh #{@ssh_opts} #{target[:host]} which cinc-solo #{@q_all}")
          `ssh #{@ssh_opts} #{target[:host]} sudo mkdir /var/cinc`
          `ssh #{@ssh_opts} #{target[:host]} sudo ln -s /var/chef/cookbooks /var/cinc/cookbooks`
          `ssh #{@ssh_opts} #{target[:host]} sudo ln -s /var/chef/roles /var/cinc/roles`
        end
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
