require "option_parser"
require "colorize"
#require "colorls/version"

module Colorls

  alias GitStatus = Bool | Hash(String,String)
  
  enum GroupBy
    None
    Dirs
    Files
  end
  
  enum SortBy
    Name
    Size
    Extension
    Time
  end

  enum DisplayMode
    Vertical
    Horizontal
    Long
    Tree
    OnePerLine
  end
  
  class Flags

    @sort : SortBy | Bool
    @parser : OptionParser
    @reverse : Bool
    
    def initialize(args : Array(String) )
      @args = args
      @light_colors = false

      @show = false
      @sort = true
      @reverse = false
      @group = GroupBy::None
      @mode = STDOUT.tty? ? DisplayMode::Vertical : DisplayMode::OnePerLine
      @all = false
      @almost_all = false
      @git_status = false
      @colors = {} of String => String
      @tree_depth = 3
      @show_group = true
      @show_user = true

      @show_report = false
      @exit_status_code = 0

      @parser = mk_parser

      parse_options

      return unless @mode == DisplayMode::Tree

      # FIXME: `--all` and `--tree` do not work together, use `--almost-all` instead
      @almost_all = true if @all
      @all = false
      
    end

    def process
      init_locale

      @args = ["."] if @args.empty? # ls the current directory

      process_args
    end

    def options
      list = @parser.top.list + @parser.base.list

      result = list.collect do |o|
        next unless o.respond_to? "desc"

        flags = o.short + o.long
        next if flags.empty?

        OpenStruct.new(flags: flags, desc: o.desc)
      end

      result.compact
    end

    

    # private
    def init_locale
      # initialize locale from environment
      #CLocale.setlocale(CLocale::LC_COLLATE, "")
    rescue e : RuntimeError
      STDERR.puts "WARN: #{e}, check your locale settings"
    end

    def group_files_and_directories
      infos = @args.flat_map do |arg|
        FileInfo.info(arg)
      rescue e : RuntimeError
        STDERR.puts "#{arg}: #{e}".colorize(:red)
        @exit_status_code = 2
        [] of FileInfo
#      rescue Errno::ENOENT
#        STDERR.puts "colorls: Specified path '#{arg}' doesn't exist.".colorize(:red)
#        @exit_status_code = 2
#        [] of String
#      rescue e : RuntimeError # SystemCallError 
#        STDERR.puts "#{path}: #{e}".colorize(:red)
#        @exit_status_code = 2
#        [] of String
      end
      infos.partition { |i| i.directory? }
    end

    def process_args
      #core = Core.new(**@opts)
      core = Core.new(@all, @sort, @show, @mode, @git_status, @almost_all, @colors, @group, @reverse, @hyperlink, @tree_depth, @show_group, @show_user)
      
      directories, files = group_files_and_directories

      core.ls_files(files) unless files.empty?

      directories.sort_by! do |a|
        ##CLocale.strxfrm(a.name)
        a.name
      end.each do |dir|
        puts "\n#{dir.show}:" if @args.size > 1

        core.ls_dir(dir)
      rescue e : RuntimeError # SystemCallError
        STDERR.puts "#{dir}: #{e}".colorize(:red)
      end

      core.display_report if @show_report

      @exit_status_code
    end


    def add_sort_options(options)
      options.separator ""
      options.separator "sorting options:"
      options.separator ""
      options.on("--sd", "--sort-dirs", "sort directories first") { @group = GroupBy::Dirs } # "--group-directories-first", 
      options.on("--sf", "--sort-files", "sort files first")                               { @group = GroupBy::Files }
      options.on("-t", "sort by modification time, newest first")                          { @sort = SortBy::Time }
      options.on("-U", "do not sort; list entries in directory order")                     { @sort = false }
      options.on("-S", "sort by file size, largest first")                                 { @sort = SortBy::Size }
      options.on("-X", "sort by file extension")                                           { @sort = SortBy::Extension }
      options.on("--sort=WORD", "sort by WORD instead of name: none, size (-S), time (-t), extension (-X)") do |word|
        valid_list = %w[none time size extension]
        case word
        when "time" then @sort = SortBy::Time
        when "size" then @sort = SortBy::Size
        when "extension" then @sort = SortBy::Extension
        when "none" then @sort = false
        else
          raise OptionParser::Exception.new("Error: Argument to --sort must be one of #{valid_list.inspect}")
        end
      end
      options.on("-r", "--reverse", "reverse order while sorting") { @reverse = true }
    end

    def add_common_options(options)
      options.on("-a", "--all", "do not ignore entries starting with .")  { @all = true }
      options.on("-A", "--almost-all", "do not list . and ..")            { @almost_all = true }
      options.on("-d", "--dirs", "show only directories")                 { @show = GroupBy::Dirs }
      options.on("-f", "--files", "show only files")                      { @show = GroupBy::Files }
      options.on("--gs", "--git-status", "show git status for each file") { @git_status = true }
      options.on("--report", "show brief report")                         { @show_report = true }
    end

    def add_format_options(options)
      options.on(
        "--format=WORD",
        "use format: across (-x), horizontal (-x), long (-l), single-column (-1), vertical (-C)"
      ) do |word|
        valid_list = %w[across horizontal long single-column]
        case word
        when "across", "horizontal" then @mode = DisplayMode::Horizontal
        when "vertical" then @mode = DisplayMode::Vertical
        when "long" then @mode = DisplayMode::Long
        when "single-column" then @mode = DisplayMode::OnePerLine
        else
          raise OptionParser::Exception.new("Error: Argument to --format must be one of #{valid_list.inspect}")
        end
      end
      options.on("-1", "list one file per line") { @mode = DisplayMode::OnePerLine }
      options.on("--tree=[DEPTH]", "shows tree view of the directory") do |depth|
        # check for Int32
        @tree_depth = depth.to_i
        @mode = DisplayMode::Tree
      end
      options.on("-x", "list entries by lines instead of by columns")     { @mode = DisplayMode::Horizontal }
      options.on("-C", "list entries by columns instead of by lines")     { @mode = DisplayMode::Vertical }
    end

    def add_long_style_options(options)
      options.on("-l", "--long", "use a long listing format")             { @mode = DisplayMode::Long }
      options.on("-o", "use a long listing format without group information") do
        @mode = DisplayMode::Long
        @show_group = false
      end
      options.on("-g", "use a long listing format without owner information") do
        @mode = DisplayMode::Long
        @show_user = false
      end
      options.on("-G", "--no-group", "show no group information in a long listing") { @show_group = false }
    end

    def add_general_options(options)
      options.separator ""
      options.separator "general options:"
      options.separator ""

      options.on(
        "--color=[WHEN]", "colorize the output: auto, always (default if omitted), never"
        # %w[always auto never] # possible allowed cases
      ) do |word|
        # let Rainbow decide in "auto" mode
        Colorize.enabled = (word != "never") unless word == "auto"
      end
      options.on("--light", "use light color scheme") { @light_colors = true }
      options.on("--dark", "use dark color scheme") { @light_colors = false }
      options.on("--hyperlink", "create hyperlinks") { @hyperlink = true }
    end

    def add_compatiblity_options(options)
      options.separator ""
      options.separator "options for compatiblity with ls (ignored):"
      options.separator ""
      options.on("-h", "--human-readable") {} # always active
    end

    def show_help
      puts @parser
      show_examples
      exit
    end

    def add_help_option(opts)
      opts.separator ""
      # Crystal OptionParser has no #on_tail method, so make sure this is last.
      opts.on("--help", "prints this help") { puts "show_help()..." }
    end

    def show_examples
      puts <<-EXAMPLES.gsub(/^  /m, "")

  examples:

    * show the given file:

      #{"colorls README.md".colorize(:green)}

    * show matching files and list matching directories:

      #{"colorls *".colorize(:green)}

    * filter output by a regular expression:

      #{"colorls | grep PATTERN".colorize(:green)}

    * several short options can be combined:

      #{"colorls -d -l -a".colorize(:green)}
      #{"colorls -dla".colorize(:green)}

EXAMPLES
    end

    def assign_each_options(opts)
      add_common_options(opts)
      add_format_options(opts)
      add_long_style_options(opts)
      add_sort_options(opts)
      add_compatiblity_options(opts)
      add_general_options(opts)
      add_help_option(opts)
    end

    def mk_parser : OptionParser
      OptionParser.new do |opts|
        opts.banner = "Usage:  colorls [OPTION]... [FILE]..."
        opts.separator ""

        assign_each_options(opts)

        # no #on_tail, so put this last
        opts.on("--version", "show version") do
          puts Colorls::VERSION
          exit
        end
      end
    end

    def parse_options
      # show help and exit if the only argument is -h
      show_help if !@args.empty? && @args.all?("-h")
      @parser.parse(@args)
      set_color_opts
    rescue e : OptionParser::Exception
      STDERR.puts "colorls: #{e}\nSee \"colorls --help\"."
      exit 2
    end

    def set_color_opts
      color_scheme_file = @light_colors ? "light_colors.yaml" : "dark_colors.yaml"
      @colors = Colorls::Yaml.new(color_scheme_file).load(aliase: true)
    end
  end
    

  
end
