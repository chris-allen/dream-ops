require "aws-sdk"
require "ridley"

Aws.use_bundled_cert!

module DreamOps
  class OpsWorksDeployer < BaseDeployer

    # Output the version of DreamOps
    def analyze(stack_ids)
      begin
        @opsworks = Aws::OpsWorks::Client.new
        stacks = @opsworks.describe_stacks({ stack_ids: stack_ids, }).stacks
      rescue => e
        DreamOps.ui.error "Failed to fetch OpsWorks stacks\n"
        DreamOps.ui.error "#{$!}"
        exit(1)
      end

      # Collect and print stack info
      result = { cookbooks: [], deploy_targets: [] }
      stacks.each do |stack|
        stack_result = analyze_stack(stack)
        # Add the stack to the deploy targets
        result[:deploy_targets] << {
          stack: stack,
          apps: stack_result[:apps],
          cookbook: stack_result[:cookbook]
        }
        # Determine whether the cookbook needs to be built
        cbook = stack_result[:cookbook]
        if !cbook.nil? && !cbook[:local_sha].nil?
          # We only build the cookbook if we don't have this version on S3
          if cbook[:remote_sha] != cbook[:local_sha]
            # Don't build the same destination cookbook more than once
            if !__cookbook_in_array(cbook, result[:cookbooks])
              result[:cookbooks] << cbook
            end
          end
        end
      end
      return result
    end

    ################## OpsWorks specific methods ##################

    # Retrieves stack apps and gets all information about remote/local cookbook
    def analyze_stack(stack)
      cookbook = nil
      cookbookName = nil

      DreamOps.ui.info "Stack: #{stack.name}"
      if !stack.custom_cookbooks_source.nil?
        source = stack.custom_cookbooks_source

        # Skip this step if the stack doesn't use S3
        if source.type == 's3'
          cookbookPath = source.url[25..-1]
          firstSlash = cookbookPath.index('/')
          cookbook = {
              bucket: cookbookPath[0..(firstSlash-1)],
              cookbook_key: cookbookPath[(firstSlash+1)..-1],
              sha_key: cookbookPath[firstSlash+1..-1].sub('.zip', '_SHA.txt')
          }

          # Treat any directory with a Berksfile as a cookbook
          cookbooks = Dir.glob('./**/Berksfile')

          # For now we only handle if we find one cookbook
          if cookbooks.length == 1
            metadata = Ridley::Chef::Cookbook::Metadata.from_file(cookbooks[0].sub("Berksfile", "metadata.rb"))
            cookbook[:name] = metadata.name
            cookbook[:path] = cookbooks[0].sub('/Berksfile', '')
            if cookbook[:cookbook_key].include? cookbook[:name]
              cookbook[:local_sha] = `git log --pretty=%H -1 #{cookbook[:path]}`.chomp

              begin
                obj = Aws::S3::Object.new(cookbook[:bucket], cookbook[:sha_key])
                cookbook[:remote_sha] = obj.get.body.string
              rescue Aws::S3::Errors::NoSuchKey
                cookbook[:remote_sha] = ''
              end
            else
              DreamOps.ui.info "Stack cookbook source is '#{cookbook[:cookbook_key]}' but found '#{cookbook[:name]}' locally"
            end
          end
          DreamOps.ui.info "--- Cookbook: #{cookbook[:name]}"
        end
      end

      apps = @opsworks.describe_apps({ stack_id: stack.stack_id }).apps
      if apps.length == 0
        DreamOps.ui.info "--- Apps: No apps"
      else
        DreamOps.ui.info "--- Apps: #{apps.map{|app| app.name}}"
      end

      return { apps: apps, cookbook: cookbook }
    end

    # Deploys cookbook to S3
    def deploy_cookbook(cookbook)
      begin
        archiveFile = File.open(cookbook[:cookbook_key])
        remoteCookbook = Aws::S3::Object.new(cookbook[:bucket], cookbook[:cookbook_key])
        response = remoteCookbook.put({ acl: "private", body: archiveFile })
        archiveFile.close

        remoteSha = Aws::S3::Object.new(cookbook[:bucket], cookbook[:sha_key])
        response = remoteSha.put({ acl: "private", body: cookbook[:local_sha] })
      rescue => e
        DreamOps.ui.error "#{$!}"
      end
    end

    # 
    def deploy_target(target, cookbooks)
      # If this stack has a new cookbook
      if !target[:cookbook].nil?
        if __cookbook_in_array(target[:cookbook], cookbooks)
          begin
            # Grab a fresh copy of the cookbook on all instances in the stack
            update_custom_cookbooks(target[:stack])
          rescue Aws::OpsWorks::Errors::ValidationException
            DreamOps.ui.error "Stack \"#{target[:stack].name}\"] has no running instances."
            __bail_with_fatal_error
          end

          # Re-run the setup step for all layers
          setup(target[:stack])
        end
      end

      # Deploy all apps for stack
      target[:apps].each do |app|
        deploy_app(app, target[:stack])
      end
    end

    def update_custom_cookbooks(stack)
      DreamOps.ui.info "...Updating custom cookbooks [stack=\"#{stack.name}\"]"
      response = @opsworks.create_deployment({
        stack_id: stack.stack_id,
        command: { name: "update_custom_cookbooks" }
      })
      return wait_for_deployment(response.deployment_id)
    end

    def setup(stack)
      DreamOps.ui.info "...Running setup command [stack=\"#{stack.name}\"]"
      response = @opsworks.create_deployment({
        stack_id: stack.stack_id,
        command: { name: "setup" }
      })
      return wait_for_deployment(response.deployment_id)
    end

    def deploy_app(app, stack)
      DreamOps.ui.info "...Deploying [stack=\"#{stack.name}\"] [app=\"#{app.name}\"]"
      response = @opsworks.create_deployment({
        stack_id: stack.stack_id,
        app_id: app.app_id,
        command: { name: "deploy" }
      })
      return wait_for_deployment(response.deployment_id)
    end

    def get_deployment_status(deployment_id)
      response = @opsworks.describe_deployments({ deployment_ids: [deployment_id] })
      if response[:deployments].length == 1
        return response[:deployments][0].status
      end
      return "failed"
    end

    def wait_for_deployment(deployment_id)
      status = "failed"
      while true
        status = get_deployment_status(deployment_id)
        break if ["successful", "failed"].include? status
        sleep(2)
      end
      return status
    end

    def __bail_with_fatal_error
      raise FatalDeployError
      Thread.exit
    end

    def __cookbook_in_array(cb, cookbooks)
      return cookbooks.any? {|c|
        c[:cookbook_key] == cb[:cookbook_key] and c[:bucket] == cb[:bucket]
      }
    end
  end
end