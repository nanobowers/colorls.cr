require "uri"
require "./monkeys"

module Colorls

  # on Windows (were the special 'nul' device exists) we need to use UTF-8
  @@file_encoding = File.exists?("nul") ? "UTF_8" : "ASCII_8BIT"

  def self.file_encoding
    @@file_encoding
  end

  def self.terminal_width : Int32
    console = IO.console

    width = IO.console_size[1]

    return width if console.nil? || console.winsize[1].zero?

    console.winsize[1]
  end

  @@screen_width : Int32
  @@screen_width = 100 # terminal_width

  def self.screen_width
    @@screen_width
  end

  class Core
    @long : Bool
    @files : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    @folders : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    @folder_aliases : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    @file_aliases : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    @tree : {mode: Bool, depth: Int32 }
    
    def initialize(@all : Bool, @sort : Bool|SortBy, @show : Bool|GroupBy , @mode : DisplayMode, @git_status : GitStatus, @almost_all : Bool, @colors : Hash(String, String), @group : GroupBy, @reverse : Bool, @hyperlink : Bool?, @tree_depth : Int32, @show_group : Bool, @show_user : Bool)

      #mode = nil, git_status = false, almost_all = false, colors = [] of String, @group = nil,
      #reverse = false, hyperlink = false, tree_depth = nil, show_group = true, show_user = true)

      @count = {} of Symbol => Int32
      @count[:folders] = 0
      @count[:recognized_files] = 0
      @count[:unrecognized_files] = 0
      #@all          = all
      #@almost_all   = almost_all
      #@hyperlink    = hyperlink
      #@sort         = sort
      #@reverse      = reverse
      #@group        = group
      #@show         = show
      #@one_per_line = mode == DisplayMode::OnePerLine
      @long = mode == DisplayMode::Long
      #@show_group = show_group
      #@show_user = show_user

      @tree         = {mode: mode == :tree, depth: tree_depth}
      #@horizontal   = mode == :horizontal
      @linklength = 0
      @userlength = 0
      @grouplength = 0
      @git_status   = init_git_status(@git_status)

      @colors  = colors
      @modes = Hash(String, String).new
 
      init_colors colors
 
      @files          = Colorls::Yaml.new("files.yaml").load()
      @file_aliases   = Colorls::Yaml.new("file_aliases.yaml").load(aliase: true)
      @folders        = Colorls::Yaml.new("folders.yaml").load
      @folder_aliases = Colorls::Yaml.new("folder_aliases.yaml").load(aliase: true)
      @contents = [] of FileInfo
    end
    
    def ls_dir(info)
      if @mode == DisplayMode::Tree
        print "\n"
        return tree_traverse(info.path, 0, 1, 2)
      end

      dir_contents = Dir.entries(info.path) #(, encoding: Colorls.file_encoding)
      dir_contents = filter_hidden_contents(dir_contents)

      contents = dir_contents.map { |e| FileInfo.dir_entry(info.path, e, link_info: @long) }

      filter_contents(contents) if @show
      sort_contents(contents)   if @sort
      group_contents(contents)  if @group

      return print "\n   Nothing to show here\n".colorize(@colors["empty"]) if contents.empty?

      ls(contents)
    end

    def ls_files(files)
      ls(files)
    end

    def display_report
      print "\n   Found #{@count.values.sum} items in total.".colorize(@colors["report"])

      puts  "\n\n\tFolders\t\t\t: #{@count[:folders]}"\
        "\n\tRecognized files\t: #{@count[:recognized_files]}"\
        "\n\tUnrecognized files\t: #{@count[:unrecognized_files]}"
        .colorize(@colors["report"])
    end

    private def ls(contents)
      init_column_lengths(contents)
      #pp contents
      layout = case @mode
               when DisplayMode::Horizontal
                 HorizontalLayout.new(contents, item_widths(contents), Colorls.screen_width)
               when [DisplayMode::OnePerLine, DisplayMode::Long]
                 SingleColumnLayout.new(contents)
               else
                 VerticalLayout.new(contents, item_widths(contents), Colorls.screen_width)
               end
      pp! layout
      layout.each_line do |line, widths|
        ls_line(line, widths)
      end
    end


    private def init_colors(colors)
      # set entries in the @colors database
      "rw-xsStT".chars.each do |key|
        filemode = case key
                   when 'r' then "read"
                   when 'w' then "write"
                   when '-' then "no_access"
                   when 'x', 's', 'S', 't', 'T' then "exec"
                   end
        modecolor = colors[filemode]
        @modes[key.to_s] = key.to_s.colorize(modecolor).to_s
      end
    end


    private def init_git_status(show_git)
      emptyreturn = {} of String => String
      return emptyreturn unless show_git

      # stores git status information per directory
#TODO
#      Hash(??,??.new do |hash, key|
#        path = File.absolute_path key.parent
#        if hash.key? path
#          hash[path]
#        else
#          hash[path] = Git.status(path)
#        end
#      end
      return emptyreturn
    end


    # how much characters an item occupies besides its name
    CHARS_PER_ITEM = 12

    def item_widths(contents) : Array(Int32)
      contents.map do |item|
        # Unicode::DisplayWidth.of(item.show) + CHARS_PER_ITEM
        if item.nil?
          CHARS_PER_ITEM
        else
          (item.show || "").size + CHARS_PER_ITEM
        end
        #item.size + CHARS_PER_ITEM
      end
    end
    
    def filter_hidden_contents(contents : Array(String)) : Array(String)
      contents -= %w[. ..] unless @all
      contents.select! { |x| !x.starts_with? '.' } unless @all || @almost_all
      contents
    end

    def init_column_lengths(contents)
      return unless @mode == DisplayMode::Long

      maxlink = maxuser = maxgroup = 0

      contents.each do |c|
        maxlink = 0 # c.nlink if c.nlink > maxlink
        maxuser = c.owner.size if c.owner.size > maxuser
        maxgroup = c.group.size if c.group.size > maxgroup
      end

      @linklength = maxlink.digits.size
      @userlength = maxuser
      @grouplength = maxgroup
    end

    def filter_contents(contents)
      contents.select! do |x|
        x.directory? == (@show == :dirs)
      end
    end

    def sort_contents(contents)
      case @sort
      when SortBy::Extension
        contents.sort_by! do |f|
          name = f.name
          ext = File.extname(name)
          name = name.chomp(ext) unless ext.empty?
          [ext, name].map { |s| s } # {CLocale.strxfrm(s) }
        end
      when SortBy::Time
        contents.sort_by! { |a| a.mtime }
      when SortBy::Size
        contents.sort_by! { |a| -a.size }
      else
        contents.sort_by! { |a| a.name } # { |a| CLocale.strxfrm(a.name) }
      end
      contents.reverse! if @reverse
    end

    def group_contents(contents)
      return unless @group

      dirs, files = contents.partition(&.directory?)

      contents = case @group
                  when GroupBy::Dirs then dirs + files
                  when GroupBy::Files then files + dirs
                  end
    end


    def format_mode(read, write, execute, special, char)
      m_r = read ? "r" : "-"
      m_w = write ? "w" : "-"
      m_x = if special
              execute ? char : char.upcase
            else
              execute ? "x" : "-"
            end

      @modes[m_r] + @modes[m_w] + @modes[m_x]
    end

    def mode_info(fileinfo)
      prm = fileinfo.permissions
      format_mode(prm.owner_read?, prm.owner_write?, prm.owner_execute?, fileinfo.flags.set_user?, 's') +
        format_mode(prm.group_read?, prm.group_write?, prm.group_execute?, fileinfo.flags.set_group?, 's') +
        format_mode(prm.other_read?, prm.other_write?, prm.other_execute?, fileinfo.flags.sticky?, 't')
    end

    def user_info(content) : String
      content.owner.ljust(@userlength, ' ').colorize(@colors["user"]).to_s
    end

    def group_info(group) : String
      group.to_s.ljust(@grouplength, ' ').colorize(@colors["normal"]).to_s
    end


    FILESIZE_PREFIXES = ["Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi"]
    
    def size_info(filesize) : String
      if filesize < 1024
        numstr = filesize.to_s
        unit = "B"
      else
        pos = (Math.log(filesize) / Math.log(1024)).floor.to_i64
        p! pos
        numstr = ( filesize / (1024 ** pos)).floor.to_s
        pos = FILESIZE_PREFIXES.size-1 if pos > FILESIZE_PREFIXES.size - 1
        unit = FILESIZE_PREFIXES[pos-1] + "B"
      end

                                                              
      #size = Filesize.new(filesize).pretty.split
      #size = "#{size[0][0..-4].rjust(4,' ')} #{size[1].ljust(3,' ')}"
      size = "#{numstr.rjust(4,' ')} #{unit.ljust(3,' ')}"
      return size.colorize(@colors["file_large"]).to_s  if filesize >= 512 * 1024 ** 2
      return size.colorize(@colors["file_medium"]).to_s if filesize >= 128 * 1024 ** 2

      size.colorize(@colors["file_small"]).to_s
    end

    def mtime_info(file_mtime) : String
      fmt = Time::Format.new("%c")
      mtime = fmt.format(file_mtime) # was... file_mtime.asctime
      now = Time.local # Time.now
      delta = (now - file_mtime).to_i
      return mtime.colorize(@colors["hour_old"]).to_s if delta < (60 * 60)
      return mtime.colorize(@colors["day_old"]).to_s  if delta < (24 * 60 * 60)

      mtime.colorize(@colors["no_modifier"]).to_s
    end

    def git_info(content): String
      return "" #TODO unless (status = @git_status[content])

      if content.directory?
        git_dir_info(content, status)
      else
        git_file_info(status[content.name])
      end
    end

    def git_file_info(status) : String
      return Git.colored_status_symbols(status, @colors) if status

      "  ✓ "
        #.encode(Encoding.default_external, undef: :replace, replace: '=')
        .colorize(@colors["unchanged"])
    end

    def git_dir_info(content, status) : String
      modes = if content.path == '.'
                Set.new(status.values).flatten
              else
                status[content.name]
              end

      if modes.empty? && Dir.empty?(content.path)
        "    "
      else
        Git.colored_status_symbols(modes, @colors)
      end
    end

    def long_info(content) : String
      return "" unless @long
      numlinks = 0 # content.nlink
      links = numlinks.to_s.rjust(@linklength)

      line_array = [mode_info(content.stats), links]
      line_array.push user_info(content) if @show_user
      line_array.push group_info(content.group) if @show_group
      line_array.concat [size_info(content.size), mtime_info(content.mtime)]
      line_array.join("   ")
    end

    def symlink_info(content)
      return "" unless @long && content.symlink?

      target = content.link_target.nil? ? "…" : content.link_target
      link_info = " ⇒ #{target}"
      if content.dead?
        "#{link_info} [Dead link]".colorize(@colors["dead_link"])
      else
        link_info.colorize(@colors["link"])
      end
    end

    def out_encode(str)
      str # str.encode(Encoding.default_external, undef: :replace, replace: "")
    end

    def fetch_string(content : FileInfo, key, color, increment : Symbol)
      @count[increment] += 1
      value = increment == :folders ? @folders[key]? : @files[key]?
      # convert unicode "\uXXXX" expressions into characters
      logo  = value.to_s.gsub(/\\u[\da-f]{4}/i) { |m| m[-4..-1].to_i(16).chr }
      name = content.show
      name = make_link(content) if @hyperlink
      name += content.directory? ? '/' : ' '
      entry = "#{out_encode(logo)}  #{out_encode(name)}"
      entry = entry.colorize.mode(:bright) if !content.directory? && content.executable?
      colorentry = entry.to_s.colorize(color)
      "#{long_info(content)} #{git_info(content)} #{colorentry}#{symlink_info(content)}"
    end

    def ls_line(chunk, widths)
      padding = 0
      line = ""
      chunk.each_with_index do |content, i|
        entry = fetch_string(content, *options(content))
        line += " " * padding
        line += "  " + entry # entry.encode(Encoding.default_external, undef: :replace)
        #padding = widths[i] - Unicode::DisplayWidth.of(content.show) - CHARS_PER_ITEM
        padding = widths[i] - content.show.size - CHARS_PER_ITEM
      end
      print line + "\n"
    end

    def file_color(file, key) : String
      color_key = case
                  when file.chardev?    then "chardev"
                  when file.blockdev?   then "blockdev"
                  when file.socket?     then "socket"
                  when file.executable? then "executable_file"
                  when @files.has_key?(key) then "recognized_file"
                  else                       "unrecognized_file"
                  end
      @colors[color_key]
    end

    def options(content : FileInfo) : { String, String, Symbol }
      if content.directory?
        key = content.name.downcase
        p! content
        p! @folders
        p! @folder_aliases

        #key = @folder_aliases[key] unless @folders.has_key? key
        #key = "folder" if key.nil?
        unless @folders.has_key? key
          key = @folder_aliases[key]? || "folder"
        end
        color = @colors["dir"]
        group = :folders
      else
        key = File.extname(content.name).sub(/^./, "").downcase
        unless @files.has_key? key
          key = @file_aliases[key]? || ""
        end
        color = file_color(content, key)
        group = @files.has_key?(key) ? :recognized_files : :unrecognized_files
        key = "file" if key.nil?
      end

      {key, color, group}
    end

    def tree_contents(path)
      dir_contents = Dir.entries(path) #, encoding: Colorls.file_encoding)

      dir_contents = filter_hidden_contents(dir_contents)

      contents = dir_contents.map { |e| FileInfo.dir_entry(path, e, link_info: @long) }

      filter_contents(contents) if @show
      sort_contents(contents)   if @sort
      group_contents(contents)  if @group

      @contents
    end

    def get_contents(path : String | Path)
      dir_contents = Dir.entries(path) #, encoding: Colorls.file_encoding)

      dir_contents = filter_hidden_contents(dir_contents)

      contents = dir_contents.map { |e| FileInfo.dir_entry(path, e, link_info: @long) }

      # TODO
      #filter_contents(contents) if @show
      #sort_contents   if @sort
      #group_contents  if @group

      #@contents
      contents
    end
    

    def tree_traverse(path, prespace, depth, indent)
      contents = tree_contents(path)
      contents.each do |content|
        icon = content == contents.last || content.directory? ? " └──" : " ├──"
        print tree_branch_preprint(prespace, indent, icon).colorize(@colors["tree"])
        print " #{fetch_string(content, *options(content))} \n"
        next unless content.directory?

        tree_traverse("#{path}/#{content}", prespace + indent, depth + 1, indent) if keep_going(depth)
      end
    end

    def keep_going(depth)
      @tree[:depth].nil? || depth < @tree[:depth]
    end

    def tree_branch_preprint(prespace, indent, prespace_icon)
      return prespace_icon if prespace.zero?

      " │ " * (prespace/indent).to_i + prespace_icon + "─" * indent
    end

    def make_link(content)
      #uri = Addressable::URI.convert_path(File.absolute_path(content.path))
      uri = "file://" + URI.encode(File.expand_path(content.path))
      "\033]8;;#{uri}\007#{content.name}\033]8;;\007"
    end
  end
end
