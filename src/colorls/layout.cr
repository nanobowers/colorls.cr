require "./fileinfo"
module Colorls
  
  abstract class Layout(T)

    def initialize(@contents : Array(T), @max_widths : Array(Int32) , @screen_width : Int32)
    end

    def each_line
      return if @contents.empty?
      self.get_chunks(chunk_size).each { |line|
        yield(compact_line(line), @max_widths)
      }
    end

    # Previously we had nils in our list, which we compacted
    # but now we use FileInfo with empty names (or Strings in the case of the unit-tests)
    # so we have to compact them out by rejecting them.
    # note we're using diff functions for String vs FileInfo..

    private def compact_line(line : Array(String))
      line.reject { |x| x == "" }
    end
    
    private def compact_line(line : Array(FileInfo))
      line.reject { |x| x.name == "" }
    end
    
    private def chunk_size : Int32
      min_size = @max_widths.min
      max_chunks = [1, @screen_width / min_size].max
      max_chunks = [max_chunks, @max_widths.size].min
      min_chunks = 1

      loop do
        mid = ((max_chunks + min_chunks).to_f / 2).ceil.to_i

        size, max_widths = self.column_widths(mid)

        if (min_chunks < max_chunks) && not_in_line(max_widths)
          max_chunks = mid - 1
        elsif min_chunks < mid
          min_chunks = mid
        else
          @max_widths = max_widths
          return size
        end
      end
    end

    private def not_in_line(max_widths : Array(Int32))
      max_widths.sum > @screen_width
    end
    
  end

  # NOTE: Why is this templated?  Shouldn't it be done with FileInfo?
  #  Well... the tests are setup to use String instead, so use templates here.
  #  Perhaps this is not the best solution.
  
  class SingleColumnLayout(T) < Layout(T)
    
    def initialize(contents : Array(T))
      super(contents, [1], 1)
    end

    private def column_widths(_mid) : {Int32, Array(Int32)}
      {1, [1]}
    end
    
    private def chunk_size : Int32
      1
    end

    private def get_chunks(_chunk_size)
      @contents.each_slice(1)
    end
    
  end

  class HorizontalLayout(T) < Layout(T)

    private def column_widths(mid : Int32) : {Int32, Array(Int32)}
      max_widths = @max_widths.each_slice(mid).to_a
      last_size = max_widths.last.size
      #max_widths.last.fill(0, last_size, max_widths.first.size - last_size)
      max_widths.last[last_size..] = [0] * (max_widths.first.size - last_size)
      {mid, max_widths.transpose.map(&.max)}
    end

    private def get_chunks(chunk_size)
      @contents.each_slice(chunk_size)
    end
  end

  class VerticalLayout(T) < Layout(T)

    private def column_widths(mid : Int32) : {Int32, Array(Int32)}
      chunk_size = (@max_widths.size.to_f / mid).ceil.to_i
      { chunk_size, @max_widths.each_slice(chunk_size).map(&.max).to_a }
    end

    private def get_chunks(chunk_size)
      columns = @contents.each_slice(chunk_size).to_a
      if columns[-1].size < chunk_size
        range = (columns[-1].size)..chunk_size-1
        range.size.times { columns[-1] << T.new() }
      end
      columns.transpose
    end
  end
end
