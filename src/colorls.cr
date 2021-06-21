# TODO: Write documentation for `Colorls`

require "./colorls/yaml"
require "./colorls/flags"
require "./colorls/fileinfo"
require "./colorls/core"

module Colorls
  VERSION = "0.1.0"
  # TODO: Put your code here
end

exit Colorls::Flags.new(ARGV).process
