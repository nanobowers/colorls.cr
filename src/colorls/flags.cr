require "option_parser"
require "colorize"

# require "colorls/version"

module Colorls
  enum DisplayHidden
    None
    All
    AlmostAll
  end

  enum Show
    All
    DirsOnly
    FilesOnly
  end

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
    None
  end

  enum DisplayMode
    Vertical
    Horizontal
    Long
    Tree
    OnePerLine
  end

  class Flags
    @parser : Optimist::Parser

    def initialize(@args : Array(String))
      @colors = {} of String => String
      @display_help_message = false
      @exit_status_code = 0
      @git_status = false
      @group = GroupBy::None
      @hidden = DisplayHidden::None
      @hyperlink = false
      @light_colors = false
      @mode = STDOUT.tty? ? DisplayMode::Vertical : DisplayMode::OnePerLine
      @reverse = false
      @show = Show::All
      @show_group = true
      @show_report = false
      @show_user = true
      @sort = SortBy::Name
      @tree_depth = 3

      @parser = mk_parser

      parse_options

      # NOTE: `--all` and `--tree` do not work together or end up with
      # a recursion issue.  Use `--almost-all` instead
      if @mode == DisplayMode::Tree && @hidden == DisplayHidden::All
        @hidden = DisplayHidden::AlmostAll
      end
    end

    def process
      @args = ["."] if @args.empty? # ls the current directory
      process_args
    end

    def group_files_and_directories
      infos = @args.flat_map do |arg|
        FileInfo.info(arg)
      rescue e : RuntimeError
        STDERR.puts "#{arg}: #{e}".colorize(:red)
        @exit_status_code = 2
        [] of FileInfo
      rescue File::NotFoundError
        STDERR.puts "colorls: Specified path '#{arg}' doesn't exist.".colorize(:red)
        @exit_status_code = 2
        [] of FileInfo
      end
      infos.partition { |i| i.directory? }
    end

    def process_args
      core = Core.new(@hidden, @sort, @show, @mode, @git_status, @colors, @group, @reverse, @hyperlink, @tree_depth, @show_group, @show_user)

      directories, files = group_files_and_directories

      core.ls_files(files) unless files.empty?

      directories.sort_by! do |a|
        a.name
      end.each do |dir|
        puts "\n#{dir.show}:" if @args.size > 1
        core.ls_dir(dir)
      rescue ex : RuntimeError
        STDERR.puts "#{dir}: #{ex}".colorize(:red)
      end

      core.display_report if @show_report

      @exit_status_code
    end

    def add_common_options(parser)
      parser.opt(:all, "do not ignore entries starting with .", short: 'a') { @hidden = DisplayHidden::All }
      parser.opt(:almost_all, "do not list . and ..", short: 'A') { @hidden = DisplayHidden::AlmostAll }
      parser.opt(:dirs, "show only directories", short: 'd') { @show = Show::DirsOnly }
      parser.opt(:files, "show only files", short: 'f') { @show = Show::FilesOnly }
      parser.opt(:git_status, "show git status for each file", alt: "gs") { @git_status = true }
      parser.opt(:report, "show brief report") { @show_report = true }
    end

    def add_format_options(parser)
      parser.opt(:format, "use format: across (-x), horizontal (-x), long (-l), single-column (-1), vertical (-C)",
        permitted: %w[across horizontal vertical long single-column], cls: String) do |evalopt|
        case evalopt.value.as(String)
        when "across", "horizontal" then @mode = DisplayMode::Horizontal
        when "vertical"             then @mode = DisplayMode::Vertical
        when "long"                 then @mode = DisplayMode::Long
        when "single-column"        then @mode = DisplayMode::OnePerLine
        end
      end

      # TODO: support '-1' option when optimist can support numeric short-opts.
      parser.opt(:one, "list one file per line", short: nil) { @mode = DisplayMode::OnePerLine }
      parser.opt(:tree, "shows tree view of the directory", cls: Int32, short: nil, default: @tree_depth) do |evalopt|
        @tree_depth = depth = evalopt.value.as(Int32)
        @mode = DisplayMode::Tree
      end
      parser.opt(:lines, "list entries by lines instead of by columns", short: 'x') { @mode = DisplayMode::Horizontal }
      parser.opt(:columns, "list entries by columns instead of by lines", short: 'C') { @mode = DisplayMode::Vertical }
    end

    def add_long_style_options(parser)
      parser.opt(:long, "use a long listing format", short: 'l') { @mode = DisplayMode::Long }
      parser.opt(:long_groupless, "use a long listing format without group information", short: 'o') do
        @mode = DisplayMode::Long
        @show_group = false
      end
      parser.opt(:long_ownerless, "use a long listing format without owner information", short: 'g') do
        @mode = DisplayMode::Long
        @show_user = false
      end
      parser.opt(:no_group, "show no group information in a long listing", short: 'G') { @show_group = false }
      # parser.conflicts :long, :long_groupless, :long_ownerless
    end

    def add_sort_options(parser)
      parser.banner ""
      parser.banner "sorting options:"
      parser.banner ""

      parser.opt(:sort_dirs, "group directories first", alt: ["sd", "group-directories-first"]) { @group = GroupBy::Dirs }
      parser.opt(:sort_files, "group files first", alt: ["sf", "group-files-first"]) { @group = GroupBy::Files }

      parser.opt(:sort_time, "sort by modification time, newest first", short: 't') { @sort = SortBy::Time }
      parser.opt(:unsorted, "do not sort; list entries in directory order", short: 'U') { @sort = SortBy::None }
      parser.opt(:sort_size, "sort by file size, largest first", short: 'S') { @sort = SortBy::Size }
      parser.opt(:sort_extension, "sort by file extension", short: 'X') { @sort = SortBy::Extension }
      parser.opt(:sort, "sort by WORD instead of name: none, size (-S), time (-t), extension (-X)",
        cls: String, permitted: %w[none time size extension]) do |evalopt|
        case evalopt.value.as(String)
        when "time"      then @sort = SortBy::Time
        when "size"      then @sort = SortBy::Size
        when "extension" then @sort = SortBy::Extension
        when "none"      then @sort = SortBy::None
        end
      end
      parser.opt(:reverse, "reverse order while sorting", short: 'r') { @reverse = true }
    end

    def add_compatiblity_options(parser)
      parser.banner ""
      parser.banner "options for compatiblity with ls (ignored):"
      parser.banner ""
      # this option is always active, but does nothing in colorls
      parser.opt :human_readable, "always enabled", short: 'h'
    end

    def add_general_options(parser)
      parser.banner ""
      parser.banner "general options:"
      parser.banner ""

      parser.opt(:color, "colorize the output", permitted: %w[auto always never], default: "auto") do |evalopt|
        case evalopt.value.as(String)
        when "always" then Colorize.enabled = true
        when "never"  then Colorize.enabled = false
        when "auto"   then Colorize.enabled = STDOUT.tty?
        end
      end

      # Forcibly disable using $NO_COLOR (www.no-color.org)
      Colorize.enabled = false if ENV.has_key?("NO_COLOR")

      parser.opt(:light, "use light color scheme", short: nil) { @light_colors = true }
      parser.opt(:dark, "use dark color scheme", short: nil) { @light_colors = false }
      parser.opt(:hyperlink, "create hyperlinks", short: nil) { @hyperlink = true }
      parser.conflicts :light, :dark
    end

    def show_help
      puts @parser.educate
      show_examples
      exit
    end

    def add_help_option(parser)
      parser.banner ""
      # Crystal OptionParser has no #on_tail method, so make sure this is last.
      parser.opt("--help", "prints this help") { @display_help_message = true }
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

    def mk_parser : Optimist::Parser
      parser = Optimist::Parser.new
      parser.version Colorls::VERSION
      parser.banner "Usage:  colorls [OPTION]... [FILE]..."
      parser.banner ""

      add_common_options(parser)
      add_format_options(parser)
      add_long_style_options(parser)
      add_sort_options(parser)
      add_compatiblity_options(parser)
      add_general_options(parser)
      add_help_option(parser)

      parser
    end

    def parse_options
      # show help and exit if the only argument is -h
      show_help if !@args.empty? && @args.all?("-h")
      @parser.parse(@args)
      show_help if @display_help_message # via --help
      set_color_opts if Colorize.enabled?
    rescue ex : Optimist::CommandlineError
      STDERR.puts "colorls: #{ex}\nSee \"colorls --help\"."
      exit 2
    end

    def set_color_opts
      color_scheme_file = @light_colors ? "light_colors.yaml" : "dark_colors.yaml"
      @colors = Colorls::Yaml.new(color_scheme_file).load(aliase: true)
    end
  end
end
