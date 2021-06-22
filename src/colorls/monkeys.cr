require "colorize"

class String
  def colorize(color : String)
    self.colorize(color)
  end

  def uniq
    chars.uniq.join
  end
end
