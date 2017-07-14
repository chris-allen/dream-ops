require "berkshelf"
# require_relative "config"
# require_relative "init_generator"
# require_relative "cookbook_generator"
# require_relative "commands/shelf"

module Dream
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

        Dream::Cli.start(@argv)
        @kernel.exit(0)
      rescue Dream::DreamError => e
        Dream.ui.error e
        Dream.ui.error "\t" + e.backtrace.join("\n\t") if ENV["BERKSHELF_DEBUG"]
        @kernel.exit(e.status_code)
      rescue Ridley::Errors::RidleyError => e
        Dream.ui.error "#{e.class} #{e}"
        Dream.ui.error "\t" + e.backtrace.join("\n\t") if ENV["BERKSHELF_DEBUG"]
        @kernel.exit(47)
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
          Dream.formatter.cleanup_hook unless config[:current_command].name == "help"
        end
      end
    end

    def initialize(*args)
      super(*args)

      # if @options[:config]
      #   unless File.exist?(@options[:config])
      #     raise ConfigNotFound.new(:berkshelf, @options[:config])
      #   end

      #   Dream.config = Dream::Config.from_file(@options[:config])
      # end

      if @options[:debug]
        ENV["BERKSHELF_DEBUG"] = "true"
        Dream.logger.level = ::Logger::DEBUG
      end

      if @options[:quiet]
        Dream.ui.mute!
      end

      Dream.set_format @options[:format]
      @options = options.dup # unfreeze frozen options Hash from Thor
    end

    namespace "berkshelf"

    map "ls"   => :list
    map "book" => :cookbook
    map ["ver", "-v", "--version"] => :version

    default_task :install

    class_option :config,
      type: :string,
      desc: "Path to Dream configuration to use.",
      aliases: "-c",
      banner: "PATH"
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
      Dream.formatter.version
    end

    desc "project", "Creates project"
    def project
      "heyoo"
    end

    tasks["cookbook"].options = Dream::CookbookGenerator.class_options

    private

      # Print a list of the given cookbooks. This is used by various
      # methods like {list} and {contingent}.
      #
      # @param [Array<CachedCookbook>] cookbooks
      #
    def print_list(cookbooks)
      Array(cookbooks).sort.each do |cookbook|
        Dream.formatter.msg "  * #{cookbook.cookbook_name} (#{cookbook.version})"
      end
    end
  end
end