require "colorize"

class String
  @@color_str_map =  { "black": Colorize::ColorANSI::Black,
                       "red": Colorize::ColorANSI::Red,
                       "green": Colorize::ColorANSI::Green,
                       "yellow": Colorize::ColorANSI::Yellow,
                       "blue": Colorize::ColorANSI::Blue,
                       "magenta": Colorize::ColorANSI::Magenta,         
                       "cyan": Colorize::ColorANSI::Cyan,
                       "light_gray": Colorize::ColorANSI::LightGray,       
                       "dark_gray": Colorize::ColorANSI::DarkGray,       
                       "light_red": Colorize::ColorANSI::LightRed,
                       "light_green": Colorize::ColorANSI::LightGreen,
                       "light_yellow": Colorize::ColorANSI::LightYellow,
                       "light_blue": Colorize::ColorANSI::LightBlue,
                       "light_magenta": Colorize::ColorANSI::LightMagenta,
                       "light_cyan": Colorize::ColorANSI::LightCyan,
                     }

  def colorize(color : String)
    self.colorize(@@color_str_map[color])
  end

  # We read colors directly from the yaml, so just do the conversion here.
  # May want to consider moving this into the yaml read...
  def colorize(color : YAML::Any)
    self.colorize(@@color_str_map[color.as_s])
  end

  def uniq
    chars.uniq.join
  end
end
