require "aws-sdk-opsworks"
require "aws-sdk-s3"
require "uri"

Aws.use_bundled_cert!

module DreamOps
  class OpsWorksDeployer < BaseDeployer

    # Analyze the OpsWorks stacks for deployment
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
    #           :cookbook_filename => "chef-app-dev.zip",
    #           :sha_filename => "chef-app-dev_SHA.txt",
    #           :name => "chef-app",
    #           :path => "./chef",
    #           :local_sha => "7bfa19491170563f422a321c144800f4435323b1",
    #           :remote_sha => ""
    #         }
    #       ],
    #       deploy_targets: [
    #         {
    #           :stack => #<Stack: name="my-stack">,
    #           :apps => [
    #             #<App: name="my-app"
    #           ],
    #           :cookbook => {
    #             :bucket => "chef-app",
    #             :cookbook_filename => "chef-app-dev.zip",
    #             :sha_filename => "chef-app-dev_SHA.txt",
    #             :name => "chef-app",
    #             :path => "./chef",
    #             :local_sha => "7bfa19491170563f422a321c144800f4435323b1",
    #             :remote_sha => ""
    #           }
    #         }
    #       ]
    #     }
    def analyze(stack_ids)
      begin
        @opsworks = Aws::OpsWorks::Client.new
        stacks = @opsworks.describe_stacks({ stack_ids: stack_ids, }).stacks
      rescue => e
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

    # Retrieves stack apps and gets all information about remote/local cookbook
    def analyze_stack(stack)
      cookbook = nil

      DreamOps.ui.info "Stack: #{stack.name}"
      if !stack.custom_cookbooks_source.nil?
        source = stack.custom_cookbooks_source

        # Skip this step if the stack doesn't use S3
        if source.type == 's3'
          cookbookPath = URI.parse(source.url).path[1..-1]
          firstSlash = cookbookPath.index('/')
          cookbook = {
              bucket: cookbookPath[0..(firstSlash-1)],
              cookbook_filename: cookbookPath[(firstSlash+1)..-1],
              sha_filename: cookbookPath[firstSlash+1..-1].sub('.zip', '_SHA.txt')
          }

          cookbooks = __get_cookbook_paths()

          # For now we only handle if we find one cookbook
          if cookbooks.length == 1
            path = cookbooks[0]
            loader = Chef::Cookbook::CookbookVersionLoader.new(path)
            loader.load_cookbooks
            cookbook_version = loader.cookbook_version
            metadata = cookbook_version.metadata

            cookbook[:name] = metadata.name
            cookbook[:path] = path
            if cookbook[:cookbook_filename].include? cookbook[:name]
              cookbook[:local_sha] = `git log --pretty=%H -1 #{cookbook[:path]}`.chomp

              begin
                obj = Aws::S3::Object.new(cookbook[:bucket], cookbook[:sha_filename])
                cookbook[:remote_sha] = obj.get.body.string
              rescue Aws::S3::Errors::NoSuchKey
                cookbook[:remote_sha] = ""
              end
            else
              DreamOps.ui.warn "Stack cookbook source is '#{cookbook[:cookbook_filename]}' but found '#{cookbook[:name]}' locally"
            end
          elsif cookbooks.length > 1
            DreamOps.ui.warn "Found more than one cookbook at paths #{cookbooks}.  Skipping build."
            cookbook[:name] = "???"
          else
            DreamOps.ui.warn "No cookbook found"
            cookbook[:name] = "???"
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
        archiveFile = File.open(cookbook[:cookbook_filename])
        remoteCookbook = Aws::S3::Object.new(cookbook[:bucket], cookbook[:cookbook_filename])
        response = remoteCookbook.put({ acl: "private", body: archiveFile })
        archiveFile.close

        remoteSha = Aws::S3::Object.new(cookbook[:bucket], cookbook[:sha_filename])
        response = remoteSha.put({ acl: "private", body: cookbook[:local_sha] })
      rescue => e
        DreamOps.ui.error "#{$!}"
      end
    end

    # 
    def deploy_target(target, cookbooks)
      # If this stack has a new cookbook
      if !target[:cookbook].nil? || DreamOps.force_setup
        if __cookbook_in_array(target[:cookbook], cookbooks) || DreamOps.force_setup
          # Grab a fresh copy of the cookbook on all instances in the stack
          update_custom_cookbooks(target[:stack])

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
      begin
        response = @opsworks.create_deployment({
          stack_id: stack.stack_id,
          command: { name: "update_custom_cookbooks" }
        })
      rescue Aws::OpsWorks::Errors::ValidationException
        __bail_with_fatal_error(NoRunningInstancesError.new(stack))
      end

      status = wait_for_deployment(response.deployment_id)
      if status != 'successful'
        __bail_with_fatal_error(OpsWorksCommandFailedError.new(
          stack, response.deployment_id, 'update_custom_cookbooks')
        )
      end
    end

    def setup(stack)
      DreamOps.ui.info "...Running setup command [stack=\"#{stack.name}\"]"
      response = @opsworks.create_deployment({
        stack_id: stack.stack_id,
        command: { name: "setup" }
      })
      
      status = wait_for_deployment(response.deployment_id)
      if status != 'successful'
        __bail_with_fatal_error(OpsWorksCommandFailedError.new(
          stack, response.deployment_id, 'setup')
        )
      end
    end

    def deploy_app(app, stack)
      DreamOps.ui.info "...Deploying [stack=\"#{stack.name}\"] [app=\"#{app.name}\"]"
      begin
        response = @opsworks.create_deployment({
          stack_id: stack.stack_id,
          app_id: app.app_id,
          command: { name: "deploy" }
        })
      rescue Aws::OpsWorks::Errors::ValidationException
        __bail_with_fatal_error(NoRunningInstancesError.new(stack))
      end

      status = wait_for_deployment(response.deployment_id)
      if status != 'successful'
        __bail_with_fatal_error(OpsWorksCommandFailedError.new(
          stack, response.deployment_id, 'deploy')
        )
      end
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
        if ["successful", "failed"].include? status
          print "\b"
          break
        end
        sleep(2)
        print "\r#{@@spinner.next}"
      end
      return status
    end

    def __cookbook_in_array(cb, cookbooks)
      return cookbooks.any? {|c|
        c[:cookbook_filename] == cb[:cookbook_filename] and c[:bucket] == cb[:bucket]
      }
    end
  end
end
