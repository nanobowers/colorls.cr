require "colorize"

class String
  @@color_str_map =  { #"black": Colorize::ColorANSI::Black,
                       #"red": Colorize::ColorANSI::Red,
                       #"green": Colorize::ColorANSI::Green,
                       #"yellow": Colorize::ColorANSI::Yellow,
                       #"blue": Colorize::ColorANSI::Blue,
                       #"magenta": Colorize::ColorANSI::Magenta,         
                       #"cyan": Colorize::ColorANSI::Cyan,
                       #"light_gray": Colorize::ColorANSI::LightGray,       
                       #"dark_gray": Colorize::ColorANSI::DarkGray,       
                       #"light_red": Colorize::ColorANSI::LightRed,
                       #"light_green": Colorize::ColorANSI::LightGreen,
                       #"light_yellow": Colorize::ColorANSI::LightYellow,
                       #"light_blue": Colorize::ColorANSI::LightBlue,
                       #"light_magenta": Colorize::ColorANSI::LightMagenta,
                       #"light_cyan": Colorize::ColorANSI::LightCyan,
                       # X11ColorNames
                       "aqua": Colorize::ColorRGB.new(0, 255, 255),
                       "aquamarine": Colorize::ColorRGB.new(127, 255, 212),
                       "mediumaquamarine": Colorize::ColorRGB.new(102, 205, 170),
                       "azure": Colorize::ColorRGB.new(240, 255, 255),
                       "beige": Colorize::ColorRGB.new(245, 245, 220),
                       "bisque": Colorize::ColorRGB.new(255, 228, 196),
                       "black": Colorize::ColorRGB.new(0, 0, 0),
                       "blanchedalmond": Colorize::ColorRGB.new(255, 235, 205),
                       "blue": Colorize::ColorRGB.new(0, 0, 255),
                       "darkblue": Colorize::ColorRGB.new(0, 0, 139),
                       "lightblue": Colorize::ColorRGB.new(173, 216, 230),
                       "mediumblue": Colorize::ColorRGB.new(0, 0, 205),
                       "aliceblue": Colorize::ColorRGB.new(240, 248, 255),
                       "cadetblue": Colorize::ColorRGB.new(95, 158, 160),
                       "dodgerblue": Colorize::ColorRGB.new(30, 144, 255),
                       "midnightblue": Colorize::ColorRGB.new(25, 25, 112),
                       "navyblue": Colorize::ColorRGB.new(0, 0, 128),
                       "powderblue": Colorize::ColorRGB.new(176, 224, 230),
                       "royalblue": Colorize::ColorRGB.new(65, 105, 225),
                       "skyblue": Colorize::ColorRGB.new(135, 206, 235),
                       "deepskyblue": Colorize::ColorRGB.new(0, 191, 255),
                       "lightskyblue": Colorize::ColorRGB.new(135, 206, 250),
                       "slateblue": Colorize::ColorRGB.new(106, 90, 205),
                       "darkslateblue": Colorize::ColorRGB.new(72, 61, 139),
                       "mediumslateblue": Colorize::ColorRGB.new(123, 104, 238),
                       "steelblue": Colorize::ColorRGB.new(70, 130, 180),
                       "lightsteelblue": Colorize::ColorRGB.new(176, 196, 222),
                       "brown": Colorize::ColorRGB.new(165, 42, 42),
                       "rosybrown": Colorize::ColorRGB.new(188, 143, 143),
                       "saddlebrown": Colorize::ColorRGB.new(139, 69, 19),
                       "sandybrown": Colorize::ColorRGB.new(244, 164, 96),
                       "burlywood": Colorize::ColorRGB.new(222, 184, 135),
                       "chartreuse": Colorize::ColorRGB.new(127, 255, 0),
                       "chocolate": Colorize::ColorRGB.new(210, 105, 30),
                       "coral": Colorize::ColorRGB.new(255, 127, 80),
                       "lightcoral": Colorize::ColorRGB.new(240, 128, 128),
                       "cornflower": Colorize::ColorRGB.new(100, 149, 237),
                       "cornsilk": Colorize::ColorRGB.new(255, 248, 220),
                       "crimson": Colorize::ColorRGB.new(220, 20, 60),
                       "cyan": Colorize::ColorRGB.new(0, 255, 255),
                       "darkcyan": Colorize::ColorRGB.new(0, 139, 139),
                       "lightcyan": Colorize::ColorRGB.new(224, 255, 255),
                       "firebrick": Colorize::ColorRGB.new(178, 34, 34),
                       "fuchsia": Colorize::ColorRGB.new(255, 0, 255),
                       "gainsboro": Colorize::ColorRGB.new(220, 220, 220),
                       "gold": Colorize::ColorRGB.new(255, 215, 0),
                       "goldenrod": Colorize::ColorRGB.new(218, 165, 32),
                       "darkgoldenrod": Colorize::ColorRGB.new(184, 134, 11),
                       "lightgoldenrod": Colorize::ColorRGB.new(250, 250, 210),
                       "palegoldenrod": Colorize::ColorRGB.new(238, 232, 170),
                       "gray": Colorize::ColorRGB.new(190, 190, 190),
                       "darkgray": Colorize::ColorRGB.new(169, 169, 169),
                       "dimgray": Colorize::ColorRGB.new(105, 105, 105),
                       "lightgray": Colorize::ColorRGB.new(211, 211, 211),
                       "slategray": Colorize::ColorRGB.new(112, 128, 144),
                       "lightslategray": Colorize::ColorRGB.new(119, 136, 153),
                       "webgray": Colorize::ColorRGB.new(128, 128, 128),
                       "green": Colorize::ColorRGB.new(0, 255, 0),
                       "darkgreen": Colorize::ColorRGB.new(0, 100, 0),
                       "lightgreen": Colorize::ColorRGB.new(144, 238, 144),
                       "palegreen": Colorize::ColorRGB.new(152, 251, 152),
                       "darkolivegreen": Colorize::ColorRGB.new(85, 107, 47),
                       "yellowgreen": Colorize::ColorRGB.new(154, 205, 50),
                       "forestgreen": Colorize::ColorRGB.new(34, 139, 34),
                       "lawngreen": Colorize::ColorRGB.new(124, 252, 0),
                       "limegreen": Colorize::ColorRGB.new(50, 205, 50),
                       "seagreen": Colorize::ColorRGB.new(46, 139, 87),
                       "darkseagreen": Colorize::ColorRGB.new(143, 188, 143),
                       "lightseagreen": Colorize::ColorRGB.new(32, 178, 170),
                       "mediumseagreen": Colorize::ColorRGB.new(60, 179, 113),
                       "springgreen": Colorize::ColorRGB.new(0, 255, 127),
                       "mediumspringgreen": Colorize::ColorRGB.new(0, 250, 154),
                       "webgreen": Colorize::ColorRGB.new(0, 128, 0),
                       "honeydew": Colorize::ColorRGB.new(240, 255, 240),
                       "indianred": Colorize::ColorRGB.new(205, 92, 92),
                       "indigo": Colorize::ColorRGB.new(75, 0, 130),
                       "ivory": Colorize::ColorRGB.new(255, 255, 240),
                       "khaki": Colorize::ColorRGB.new(240, 230, 140),
                       "darkkhaki": Colorize::ColorRGB.new(189, 183, 107),
                       "lavender": Colorize::ColorRGB.new(230, 230, 250),
                       "lavenderblush": Colorize::ColorRGB.new(255, 240, 245),
                       "lemonchiffon": Colorize::ColorRGB.new(255, 250, 205),
                       "lime": Colorize::ColorRGB.new(0, 255, 0),
                       "linen": Colorize::ColorRGB.new(250, 240, 230),
                       #"magenta": Colorize::ColorRGB.new(255, 0, 255),
                       "darkmagenta": Colorize::ColorRGB.new(139, 0, 139),
                       "maroon": Colorize::ColorRGB.new(176, 48, 96),
                       "webmaroon": Colorize::ColorRGB.new(127, 0, 0),
                       "mintcream": Colorize::ColorRGB.new(245, 255, 250),
                       "mistyrose": Colorize::ColorRGB.new(255, 228, 225),
                       "moccasin": Colorize::ColorRGB.new(255, 228, 181),
                       "oldlace": Colorize::ColorRGB.new(253, 245, 230),
                       "olive": Colorize::ColorRGB.new(128, 128, 0),
                       "olivedrab": Colorize::ColorRGB.new(107, 142, 35),
                       "orange": Colorize::ColorRGB.new(255, 165, 0),
                       "darkorange": Colorize::ColorRGB.new(255, 140, 0),
                       "orchid": Colorize::ColorRGB.new(218, 112, 214),
                       "darkorchid": Colorize::ColorRGB.new(153, 50, 204),
                       "mediumorchid": Colorize::ColorRGB.new(186, 85, 211),
                       "papayawhip": Colorize::ColorRGB.new(255, 239, 213),
                       "peachpuff": Colorize::ColorRGB.new(255, 218, 185),
                       "peru": Colorize::ColorRGB.new(205, 133, 63),
                       "pink": Colorize::ColorRGB.new(255, 192, 203),
                       "deeppink": Colorize::ColorRGB.new(255, 20, 147),
                       "lightpink": Colorize::ColorRGB.new(255, 182, 193),
                       "hotpink": Colorize::ColorRGB.new(255, 105, 180),
                       "plum": Colorize::ColorRGB.new(221, 160, 221),
                       "purple": Colorize::ColorRGB.new(160, 32, 240),
                       "mediumpurple": Colorize::ColorRGB.new(147, 112, 219),
                       "rebeccapurple": Colorize::ColorRGB.new(102, 51, 153),
                       "webpurple": Colorize::ColorRGB.new(127, 0, 127),
                       "red": Colorize::ColorRGB.new(255, 0, 0),
                       "darkred": Colorize::ColorRGB.new(139, 0, 0),
                       "orangered": Colorize::ColorRGB.new(255, 69, 0),
                       "mediumvioletred": Colorize::ColorRGB.new(199, 21, 133),
                       "palevioletred": Colorize::ColorRGB.new(219, 112, 147),
                       "salmon": Colorize::ColorRGB.new(250, 128, 114),
                       "darksalmon": Colorize::ColorRGB.new(233, 150, 122),
                       "lightsalmon": Colorize::ColorRGB.new(255, 160, 122),
                       "seashell": Colorize::ColorRGB.new(255, 245, 238),
                       "sienna": Colorize::ColorRGB.new(160, 82, 45),
                       "silver": Colorize::ColorRGB.new(192, 192, 192),
                       "darkslategray": Colorize::ColorRGB.new(47, 79, 79),
                       "snow": Colorize::ColorRGB.new(255, 250, 250),
                       "tan": Colorize::ColorRGB.new(210, 180, 140),
                       "teal": Colorize::ColorRGB.new(0, 128, 128),
                       "thistle": Colorize::ColorRGB.new(216, 191, 216),
                       "tomato": Colorize::ColorRGB.new(255, 99, 71),
                       "turquoise": Colorize::ColorRGB.new(64, 224, 208),
                       "darkturquoise": Colorize::ColorRGB.new(0, 206, 209),
                       "mediumturquoise": Colorize::ColorRGB.new(72, 209, 204),
                       "paleturquoise": Colorize::ColorRGB.new(175, 238, 238),
                       "violet": Colorize::ColorRGB.new(238, 130, 238),
                       "darkviolet": Colorize::ColorRGB.new(148, 0, 211),
                       "blueviolet": Colorize::ColorRGB.new(138, 43, 226),
                       "wheat": Colorize::ColorRGB.new(245, 222, 179),
                       "white": Colorize::ColorRGB.new(255, 255, 255),
                       "antiquewhite": Colorize::ColorRGB.new(250, 235, 215),
                       "floralwhite": Colorize::ColorRGB.new(255, 250, 240),
                       "ghostwhite": Colorize::ColorRGB.new(248, 248, 255),
                       "navajowhite": Colorize::ColorRGB.new(255, 222, 173),
                       "whitesmoke": Colorize::ColorRGB.new(245, 245, 245),
                       "yellow": Colorize::ColorRGB.new(255, 255, 0),
                       "lightyellow": Colorize::ColorRGB.new(255, 255, 224),
                       "greenyellow": Colorize::ColorRGB.new(173, 255, 47)
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
