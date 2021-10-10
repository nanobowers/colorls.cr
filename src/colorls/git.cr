require "./monkeys"

# notes:
# + Process.new with a block doesnt return a value, instead it raises if it failed?
# + can we use libgit or something?

module Colorls
  module Git
    def self.status(repo_path)
      prefix, success = git_prefix(repo_path)
      prefixstr = prefix.is_a?(String) ? prefix : ""
      return unless success

      prefix_path = Path[prefixstr]

      git_status = Hash(String, Set(String)).new { |hash, key| hash[key] = Set(String).new }

      git_subdir_status(repo_path) do |mode, file|
        if file == prefix
          # git_status.default = Set[mode].freeze
        else
          # path = Path[file].relative_path_from(prefix_path)
          path = Path[file].relative_to(prefix_path)
          # git_status[path.descend.first.cleanpath.to_s].add(mode)
          git_status[path.parts.first.to_s].add(mode)
        end
      end

      # p! $?
      # STDERR.puts "git status failed in #{repo_path}" unless $?.success?  # $CHILD_STATUS.success?

      # git_status.default = Set.new.freeze if git_status.default.nil?
      # git_status.freeze
      git_status
    end

    def self.colored_status_symbols(modes, colors)
      if modes.empty?
        return "  ✓ "
          # .encode(Encoding.default_external, undef: :replace, replace: '=')
          .colorize(colors["unchanged"])
      end

      modes.to_a.join.uniq.delete('!').rjust(3).ljust(4)
        .sub('?', "?".colorize(colors["untracked"]))
        .sub('A', "A".colorize(colors["addition"]))
        .sub('M', "M".colorize(colors["modification"]))
        .sub('D', "D".colorize(colors["deletion"]))
    end

    def self.git_prefix(repo_path : String)
      ioresult = IO::Memory.new
      Process.run("git", ["-C", repo_path, "rev-parse", "--show-prefix"], output: ioresult)
      return [ioresult.to_s.chomp, $?.success?]
    rescue RuntimeError # Errno::ENOENT
      return [nil, false]
    end

    def self.git_subdir_status(repo_path : String) # : Int32
      Process.run("git", ["-C", repo_path, "status", "--porcelain", "-z", "-unormal", "--ignored", "."]) do |process_id|
        # #DEBUG## puts; p! process_id ; puts
        output = process_id.output
        while (status_line = output.gets '\0')
          mode, file = status_line.chomp('\0').lstrip.split(" ", 2)
          yield mode, file
          # skip the next \x0 separated original path for renames, issue #185
          output.gets('\0') if mode.starts_with? 'R'
        end
      end
      # return $?
      # return z
    end
  end
end
