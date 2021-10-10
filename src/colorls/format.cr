module Colorls
  # Breakout some of the formatting portions so they are easier to test.

  module Format
    # It is impractical that we will actually see some of these prefixes because
    # the filesize is stored in an Int64, and Exa+ sizes cant be represented.

    FILESIZE_PREFIXES = ["Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi"]

    def self.filesize_string(filesize : Int64) : String
      if filesize < 1024
        numstr = filesize.to_s
        unit = "B"
      else
        pos = (Math.log(filesize) / Math.log(1024)).floor.to_i64
        numadj = filesize / (1024.to_i64 ** pos)
        numstr = if numadj < 10
                   sprintf("%.1f", numadj)
                 else
                   sprintf("%d", numadj.round)
                 end
        pos = FILESIZE_PREFIXES.size - 1 if pos > FILESIZE_PREFIXES.size - 1
        unit = FILESIZE_PREFIXES[pos - 1] + "B"
      end

      "#{numstr.rjust(4, ' ')} #{unit.ljust(3, ' ')}"
    end
  end
end
