require "aws-sdk"
require "ridley"

module DreamOps
  class OpsWorksDeployer < BaseDeployer

    def analyze_stack(stack, output=true)
      # DreamOps.ui.info stack
      cookbook = nil
      cookbookName = nil

      if output
        DreamOps.ui.info "Stack: #{stack.name}"
      end
      if !stack.custom_cookbooks_source.nil?
        source = stack.custom_cookbooks_source
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
                cookbook['remote_sha'] = obj.get.body.string
              rescue Aws::S3::Errors::NoSuchKey
                cookbook['remote_sha'] = ''
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
        if output
          DreamOps.ui.info "--- Apps: No apps"
        end
      else
        if output
          DreamOps.ui.info "--- Apps: #{apps.map{|app| app.name}}"
        end
      end
      # DreamOps.ui.info apps
      return { apps: apps, cookbook: cookbook }
    end

    def deploy_cookbook(cookbook)
      DreamOps.ui.info "deploy_cookbook"
    end

    # Output the version of DreamOps
    def analyze(stack_ids)
      Aws.use_bundled_cert!
      cookbooks_to_build = []
      begin
        @opsworks = Aws::OpsWorks::Client.new
        stacks = @opsworks.describe_stacks({ stack_ids: stack_ids, })
      rescue => e
        DreamOps.ui.error "Failed to fetch OpsWorks stacks\n"
        DreamOps.ui.error "#{$!}"
        exit(1)
      end

      # Collect and print stack info
      stacks.stacks.each do |stack|
        result = analyze_stack(stack)
        cbook = result[:cookbook]
        if !cbook.nil? && !cbook[:local_sha].nil?
          # We only build the cookbook if we don't have this version on S3
          if cbook[:remote_sha] != cbook[:local_sha]
            cbook_in_array = cookbooks_to_build.any? {|c|
              c[:cookbook_key] == cbook[:cookbook_key] and c[:bucket] == cbook[:bucket]
            }
            if !cbook_in_array
              cookbooks_to_build << cbook
            end
          end
        end
      end
      return cookbooks_to_build
    end
  end
end