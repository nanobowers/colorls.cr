#require "forwardable"

require "system/user"
require "system/group"

module Colorls

  class FileInfo

    @show_name : String
    @path : String
    @@users  = {} of String => String
    @@groups = {} of String => String

    getter :stats, :name, :path, :parent

    def initialize(@name : String, @parent : String, path : String? = nil , @link_info = true)
      @path = path.nil? ? File.join(parent, name) : path
      #@ftype = File::Type.new()
      @stats = File.info(@path, follow_symlinks: false)
      @show_name = ""

      # TODO:
      # @path.force_encoding(Colorls.file_encoding)

      handle_symlink(@path) if link_info && @stats.symlink?
    end

    def self.info(path : String, link_info=true)
      FileInfo.new(name: File.basename(path),
                   parent: File.dirname(path),
                   path: path, link_info: link_info)
    end

    def self.dir_entry(dir : String, child : String , link_info : Bool = true) : FileInfo
      FileInfo.new(name: child, parent: dir, link_info: link_info)
    end

    def show : String
      return @show_name unless @show_name.nil?
      @show_name = @name
      #TODO
      #@show_name = @name.encode(Encoding.find("filesystem"), Encoding.default_external, invalid: :replace, undef: :replace)
    end

    def dead?
      @dead
    end

    def owner
      return @@users[@stats.owner_id] if @@users.has_key? @stats.owner_id
      user = System::User.find_by?(id: @stats.owner_id)
      @@users[@stats.owner_id] = user.nil? ? @stats.owner_id.to_s : user.name
    rescue ArgumentError
      @stats.owner_id.to_s
    end

    def group
      return @@groups[@stats.group_id] if @@groups.has_key? @stats.group_id
      group = System::Group.find_by?(id: @stats.group_id)
      #MISSING group = Etc.getgrgid(@stats.group_id)
      #group = nil
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

    def directory? ; @stats.directory? ; end
    def chardev? ; @stats.type.character_device? ; end
    def blockdev? ; @stats.type.block_device? ; end
    def socket? ; @stats.type.socket? ; end
    def executable? ; File.executable?(@path) ; end
    def size ; @stats.size ; end
    def mtime ; @stats.modification_time ; end
    def symlink? ; File.symlink?(@path) ; end
    
    #def_delegators :@stats, :directory?, :socket?, :chardev?, :symlink?, :blockdev?, :mtime, :nlink, :size, :owned?,\
    #               :executable?

    #private

    def handle_symlink(path)
      @target = File.readlink(path)
      @dead = !File.exists?(path)
    rescue e : RuntimeError # SystemCallError
      STDERR.puts "cannot read symbolic link: #{e}"
    end
  end

  class EmptyFileInfo < FileInfo
    def initialize(@name : String)
      #@ftype = File::Type.new()
      @link_info = false
      @parent = ""
      @path = ""
      @stats = File.info("/tmp", follow_symlinks: false)
      @show_name = ""
      @target = nil
      @dead = false
    end
    def show ; "" ; end
  end
  
end
