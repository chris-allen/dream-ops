require "dream-ops"

# require_relative "init_generator"
# require_relative "cookbook_generator"
# require_relative "commands/shelf"


module DreamOps
  class Cli < Thor
    # This is the main entry point for the CLI. It exposes the method {#execute!} to
    # start the CLI.
    #
    # @note the arity of {#initialize} and {#execute!} are extremely important for testing purposes. It
    #   is a requirement to perform in-process testing with Aruba. In process testing is much faster
    #   than spawning a new Ruby process for each test.
    class Runner
      def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
        @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
      end

      def execute!
        $stdin  = @stdin
        $stdout = @stdout
        $stderr = @stderr

        DreamOps::Cli.start(@argv)
        @kernel.exit(0)
      rescue DreamOps::DreamOpsError => e
        DreamOps.ui.error e
        DreamOps.ui.error "\t" + e.backtrace.join("\n\t") if ENV["DREAMOPS_DEBUG"]
        @kernel.exit(e.status_code)
      end
    end

    class << self
      def dispatch(meth, given_args, given_opts, config)
        if given_args.length > 1 && !(given_args & Thor::HELP_MAPPINGS).empty?
          command = given_args.first

          if subcommands.include?(command)
            super(meth, [command, "help"].compact, nil, config)
          else
            super(meth, ["help", command].compact, nil, config)
          end
        else
          super
          DreamOps.formatter.cleanup_hook unless config[:current_command].name == "help"
        end
      end
    end

    def initialize(*args)
      super(*args)

      if @options[:debug]
        ENV["DREAMOPS_DEBUG"] = "true"
        DreamOps.logger.level = ::Logger::DEBUG
      else
        Berkshelf.ui.mute!
      end

      if @options[:quiet]
        DreamOps.ui.mute!
      end

      DreamOps.set_format @options[:format]
      @options = options.dup # unfreeze frozen options Hash from Thor
    end

    namespace "dream-ops"

    # map "ls"   => :list
    map ["ver", "-v", "--version"] => :version

    default_task :version

    class_option :format,
      type: :string,
      default: "human",
      desc: "Output format to use.",
      aliases: "-F",
      banner: "FORMAT"
    class_option :quiet,
      type: :boolean,
      desc: "Silence all informational output.",
      aliases: "-q",
      default: false
    class_option :debug,
      type: :boolean,
      desc: "Output debug information",
      aliases: "-d",
      default: false

    desc "version", "Display version"
    def version
      DreamOps.formatter.version
    end

    method_option :stacks,
      type: :array,
      desc: "Only these stack IDs.",
      aliases: "-s",
      required: true
    desc "deploy [TYPE]", "Deploys to specified targets"
    def deploy(type)
      deployer = nil

      args = []
      if type == 'opsworks'
        deployer = OpsWorksDeployer.new
        stack_ids = options[:stacks]
        args = [*stack_ids]
      else
        DreamOps.ui.error "Deployment of type '#{type}' is not supported"
        exit(1)
      end

      if !deployer.nil?
        deployer.deploy(*args)
      end
    end
  end
end
