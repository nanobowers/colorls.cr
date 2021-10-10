require "uri"
require "./monkeys"
require "./git"

module Colorls

  FILE_LARGE_THRESHOLD = (512 * 1024 ** 2)
  FILE_MEDIUM_THRESHOLD = (128 * 1024 ** 2)

  class GitStatus
    getter :enabled
    def initialize(@enabled : Bool)
      @hash = {} of String => Hash(String, Set(String))?
    end
    
    def [](key : FileInfo)
      path = File.expand_path key.parent
      if @hash.has_key? path
        @hash[path]
      else
        @hash[path] = Git.status(path)
      end
    end
    
  end

#  # on Windows (were the special 'nul' device exists) we need to use UTF-8
#  @@file_encoding = File.exists?("nul") ? "UTF_8" : "ASCII_8BIT"
#  def self.file_encoding
#    @@file_encoding
#  end



  # Get the width-info from the TTY and save it as a class var.
  @@screen_width : Int32 = Term::Screen.width

  def self.screen_width
    @@screen_width
  end


  class Core
    @long : Bool
    @files : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    @folders : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    @folder_aliases : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    @file_aliases : Hash(String, String) # Hash(YAML::Any, YAML::Any)
    
    def initialize(@hidden : DisplayHidden, @sort : SortBy, @show : Show , @mode : DisplayMode, git_status_enable : Bool, @colors : Hash(String, String), @group : GroupBy, @reverse : Bool, @hyperlink : Bool?, @tree_depth : Int32, @show_group : Bool, @show_user : Bool)

      # TODO: convert to a struct
      @count = {} of Symbol => Int32
      @count[:folders] = 0
      @count[:recognized_files] = 0
      @count[:unrecognized_files] = 0
      
      @long = (mode == DisplayMode::Long)
      @linklength = 0
      @userlength = 0
      @grouplength = 0
      @git_status = GitStatus.new(git_status_enable)

      @colors  = colors
      @modes = Hash(String, String).new
 
      init_colors colors

      @files          = Colorls::Yaml.new("files.yaml").load()
      @file_aliases   = Colorls::Yaml.new("file_aliases.yaml").load(aliase: true)
      @folders        = Colorls::Yaml.new("folders.yaml").load
      @folder_aliases = Colorls::Yaml.new("folder_aliases.yaml").load(aliase: true)
    end

    # Takes a directory-path, finds all files/dirs in it and returns
    # the filtered/sorted/grouped contents
    def get_dir_contents(path : String | Path) : Array(FileInfo)
      dir_contents = Dir.entries(path)
      dir_contents = filter_hidden_contents(dir_contents)
      
      contents = dir_contents.map { |e| FileInfo.dir_entry(path, e, link_info: @long) }
      
      contents = filter_contents(contents)
      contents = sort_contents(contents)
      contents.reverse! if @reverse
      contents = group_contents(contents)
      return contents
    end
    
    def ls_dir(info : FileInfo)
      if @mode == DisplayMode::Tree
        print "\n"
        return tree_traverse(info.path, 0, 1, 2)
      end
      contents = get_dir_contents(info.path)

      return print "\n   Nothing to show here\n".colorize(@colors["empty"]) if contents.empty?

      ls(contents)
    end

    def ls_files(files)
      ls(files)
    end

    def display_report
      print "\n   Found #{@count.values.sum} items in total.".colorize(@colors["report"])

      puts  "\n\n\tFolders\t\t\t: #{@count[:folders]}" \
        "\n\tRecognized files\t: #{@count[:recognized_files]}" \
        "\n\tUnrecognized files\t: #{@count[:unrecognized_files]}"
        .colorize(@colors["report"])
    end

    private def ls(contents)
      init_column_lengths(contents)
      layout = case @mode
               when DisplayMode::Horizontal
                 HorizontalLayout.new(contents, item_widths(contents), Colorls.screen_width)
               when DisplayMode::OnePerLine, DisplayMode::Long
                 SingleColumnLayout.new(contents)
               else
                 VerticalLayout.new(contents, item_widths(contents), Colorls.screen_width)
               end
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


#    private def init_git_status(show_git)
#      gitmap = {} of String => String
#      return gitmap unless show_git
#
      # stores git status information per directory
#      Hash(??,??).new do |hash, key|
#        path = File.absolute_path key.parent
#        if hash.key? path
#          hash[path]
#        else
#          hash[path] = Git.status(path)
#        end
#      end
#      return gitmap
#    end


    # how much characters an item occupies besides its name
    CHARS_PER_ITEM = 12

    def item_widths(contents) : Array(Int32)
      contents.map do |item|
        UnicodeCharWidth.width(item.show || "") + CHARS_PER_ITEM
      end
    end

    # Remove contents from an array based on hidden property
    def filter_hidden_contents(contents : Array(String)) : Array(String)
      case @hidden
      in DisplayHidden::All
        contents
      in DisplayHidden::AlmostAll
        contents - %w[. ..]
      in DisplayHidden::None
        contents.reject! { |x| x.starts_with? '.' }
      end
    end

    def init_column_lengths(contents)
      return unless @mode == DisplayMode::Long

      maxlink = maxuser = maxgroup = 0

      contents.each do |c|
        maxlink = c.nlink if c.nlink > maxlink
        maxuser = c.owner.size if c.owner.size > maxuser
        maxgroup = c.group.size if c.group.size > maxgroup
      end

      @linklength = maxlink.digits.size
      @userlength = maxuser
      @grouplength = maxgroup
    end

    # Return filtered content array
    def filter_contents(contents : Array(FileInfo)) : Array(FileInfo)
      case @show
      in Show::All then contents
      in Show::DirsOnly then contents.select(&.directory?)
      in Show::FilesOnly then contents.reject(&.directory?)
      end
    end

    # Return sorted content-array
    def sort_contents(contents : Array(FileInfo)) : Array(FileInfo)
      case @sort
      in SortBy::Extension
        contents.sort_by do |f|
          name = f.name
          ext = File.extname(name)
          name = name.chomp(ext) unless ext.empty?
          [ext, name].map { |s| s }
        end
      in SortBy::Time
        contents.sort_by { |a| a.mtime }
      in SortBy::Size
        contents.sort_by { |a| -a.size }
      in SortBy::Name
        contents.sort_by { |a| a.name }
      in SortBy::None
        contents
      end
    end

    # Return grouped content-array
    def group_contents(contents : Array(FileInfo)) : Array(FileInfo)
      case @group
      in GroupBy::None then contents
      in GroupBy::Dirs
        dirs, files = contents.partition(&.directory?)
        dirs + files
      in GroupBy::Files
        dirs, files = contents.partition(&.directory?)
        files + dirs
      end
    end


    def format_mode(read, write, execute, special, char)
      m_r = read ? "r" : "-"
      m_w = write ? "w" : "-"
      m_x = if special
              (execute ? char : char.upcase).to_s
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


    def size_info(filesize) : String
      size = Format.filesize_string(filesize)
      return size.colorize(@colors["file_large"]).to_s  if filesize >= FILE_LARGE_THRESHOLD
      return size.colorize(@colors["file_medium"]).to_s if filesize >= FILE_MEDIUM_THRESHOLD
      size.colorize(@colors["file_small"]).to_s
    end

    def mtime_info(file_mtime) : String
      fmt = Time::Format.new("%c")
      mtime = fmt.format(file_mtime) # was... file_mtime.asctime
      delta = Time.local - file_mtime
      return mtime.colorize(@colors["hour_old"]).to_s if delta < 1.hour
      return mtime.colorize(@colors["day_old"]).to_s  if delta < 1.day
      mtime.colorize(@colors["no_modifier"]).to_s
    end

    def git_info(content : FileInfo): String
      # bail early if disabled
      return "" unless @git_status.enabled
      status = @git_status[content]
      # also bail early if nil (not a git-dir)
      return "" if status.nil?
      
      if content.directory?
        git_dir_info(content, status)
      else
        git_file_info(status[content.name])
      end
    end

    def git_file_info(status) : String
      rval = if status
               Git.colored_status_symbols(status, @colors)
             else
               "  ✓ ".colorize(@colors["unchanged"])
             end
      rval.to_s
    end

    def git_dir_info(content, status) : String
      modes = if content.path == '.'
                status.values # status should be a set..
              else
                status[content.name]
              end

      if modes.empty? && Dir.empty?(content.path)
        "    "
      else
        Git.colored_status_symbols(modes, @colors).to_s
      end
    end

    def long_info(content) : String
      return "" unless @long
      numlinks = content.nlink
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
      value = (increment == :folders) ? @folders[key]? : @files[key]?
      # convert unicode "\uXXXX" expressions into characters
      logo  = value.to_s.gsub(/\\u[\da-f]{4}/i) { |m| m[-4..-1].to_i(16).chr }
      name = content.show()
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
        padding = widths[i] - UnicodeCharWidth.width(content.show) - CHARS_PER_ITEM
      end
      print line + "\n"
    end

    def file_color(file, key) : String
      color_key = case
                  when file.chardev?    then "chardev"
                  when file.blockdev?   then "blockdev"
                  when file.socket?     then "socket"
                  when file.executable? then "executable_file"
                  when key == "file"   then  "unrecognized_file"
                  when @files.has_key?(key) then "recognized_file"
                  else "unrecognized_file"
                  end
      @colors[color_key]
    end

    def options(content : FileInfo) : { String, String, Symbol }
      if content.directory?
        key = content.name.downcase
        unless @folders.has_key? key
          key = @folder_aliases[key]? || "folder"
        end
        color = @colors["dir"]
        group = :folders
      else
        # "file" is the unrecognized value
        key = File.extname(content.name).sub(/^\./, "").downcase
        unless @files.has_key? key
          key = @file_aliases[key]? || "file"
        end
        color = file_color(content, key)
        group = key == "file" ? :unrecognized_files : :recognized_files
      end
      
      return {key, color, group}
    end

    def tree_traverse(path : String | Path, prespace, depth : Int32, indent)
      contents = get_dir_contents(path)
      contents.each do |content|
        icon = content == contents.last || content.directory? ? " └──" : " ├──"
        print tree_branch_preprint(prespace, indent, icon).colorize(@colors["tree"])
        print " #{fetch_string(content, *options(content))} \n"
        next unless content.directory?
        
        tree_traverse("#{path}/#{content.name}", prespace + indent, depth + 1, indent) if keep_going(depth)
      end
    end

    def keep_going(depth)
      depth < @tree_depth
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
