# TODO: Write documentation for `Colorls`
require "uniwidth"

require "./colorls/yaml"
require "./colorls/flags"
require "./colorls/fileinfo"
require "./colorls/layout"
require "./colorls/core"

module Colorls
  VERSION = "0.0.1"
end

exit Colorls::Flags.new(ARGV).process
