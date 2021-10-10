# require "forwardable"

require "system/user"
require "system/group"

module Colorls
  class FileInfo
    @@users = {} of String => String
    @@groups = {} of String => String

    @show_name : String?
    @path : String

    getter :stats, :name, :path, :parent

    def initialize(@name : String, @parent : String, path : String? = nil, @link_info = true)
      @path = path.nil? ? File.join(parent, name) : path
      # @ftype = File::Type.new()
      @stats = File.info(@path, follow_symlinks: false)
      @show_name = nil

      # TODO:
      # @path.force_encoding(Colorls.file_encoding)

      handle_symlink(@path) if link_info && @stats.symlink?
    end

    # Return an empty fileinfo object
    # This is to used to temporarily pad out a 2D array of FileInfo objects
    # and then thrown away..
    def initialize
      @name = ""
      @path = ""
      @show_name = ""
      @parent = ""
      @link_info = false
      # hopefully current dir exists, this is only initialized because it's
      # expensive to make the type-checker allow nils here.
      @stats = File.info(".")
    end

    def self.info(path : String, link_info = true)
      FileInfo.new(name: File.basename(path),
        parent: File.dirname(path),
        path: path, link_info: link_info)
    end

    def self.dir_entry(dir : String, child : String, link_info : Bool = true) : FileInfo
      FileInfo.new(name: child, parent: dir, link_info: link_info)
    end

    def show : String
      if @show_name.nil?
        # TODO @show_name = @name.encode(Encoding.find("filesystem"), Encoding.default_external, invalid: :replace, undef: :replace)
        @show_name = @name
        return @name
      else
        return @show_name.as(String)
      end
    end

    def dead?
      @dead
    end

    def owner
      owner_id = @stats.owner_id
      return @@users[owner_id] if @@users.has_key?(owner_id)
      user = System::User.find_by(id: owner_id)
      @@users[owner_id] = user.username # sometimes user.name is the empty-string??

    rescue System::User::NotFoundError
      @stats.owner_id.to_s
    end

    def group
      return @@groups[@stats.group_id] if @@groups.has_key? @stats.group_id
      group = System::Group.find_by?(id: @stats.group_id)
      # MISSING group = Etc.getgrgid(@stats.group_id)
      # group = nil
      @@groups[@stats.group_id] = group.nil? ? @stats.group_id.to_s : group.name
    rescue ArgumentError
      @stats.group_id.to_s
    end

    # target of a symlink (only available for symlinks)
    def link_target
      @target
    end

    def to_s
      name
    end

    def directory?
      @stats.directory?
    end

    def chardev?
      @stats.type.character_device?
    end

    def blockdev?
      @stats.type.block_device?
    end

    def socket?
      @stats.type.socket?
    end

    def executable?
      File.executable?(@path)
    end

    def size
      @stats.size
    end

    def mtime
      @stats.modification_time
    end

    def symlink?
      File.symlink?(@path)
    end

    # note: crystal doesnt have nlink so we have to monkey-patch it in (in monkeys.cr)
    def nlink
      @stats.nlink
    end

    # def_delegators  :owned?, :executable?

    private def handle_symlink(path)
      @target = File.readlink(path)
      @dead = !File.exists?(path)
    rescue e : RuntimeError # SystemCallError
      STDERR.puts "cannot read symbolic link: #{e}"
    end
  end

  class EmptyFileInfo < FileInfo
    def initialize(@name : String)
      # @ftype = File::Type.new()
      @link_info = false
      @parent = ""
      @path = ""
      @stats = File.info("/tmp", follow_symlinks: false)
      @show_name = ""
      @target = nil
      @dead = false
    end

    def show
      ""
    end
  end
end
