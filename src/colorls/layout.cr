module Colorls
  
  abstract class Layout

    @max_widths : Array(Int32) # typing
    
    # how much characters an item occupies besides its name
    CHARS_PER_ITEM = 12

    def initialize(@contents : Array(FileInfo), @screen_width : Int32)
      @max_widths = @contents.map do |item|
        # Unicode::DisplayWidth.of(item.show) + CHARS_PER_ITEM
        item.show.size + CHARS_PER_ITEM
      end
    end

    def each_line
      return if @contents.empty?

      get_chunks(chunk_size).each { |line| yield(line.compact, @max_widths) }
    end

#    private

    def chunk_size : Int32
      min_size = @max_widths.min
      max_chunks = [1, @screen_width / min_size].max
      max_chunks = [max_chunks, @max_widths.size].min
      min_chunks = 1

      loop do
        mid = ((max_chunks + min_chunks).to_f / 2).ceil.to_i

        size, max_widths = self.column_widths(mid)

        if min_chunks < max_chunks && not_in_line(max_widths)
          max_chunks = mid - 1
        elsif min_chunks < mid
          min_chunks = mid
        else
          @max_widths = max_widths
          return size
        end
      end
    end

    def not_in_line(max_widths)
      max_widths.sum > @screen_width
    end
  end

  class SingleColumnLayout < Layout
    def initialize(contents)
      super(contents, 1)
    end

    #private
    def column_widths(_mid) 
      1 ###????
    end
    
    def chunk_size : Int32
      1
    end

    def get_chunks(_chunk_size)
      @contents.each_slice(1)
    end
  end

  class HorizontalLayout < Layout
    #private

    def column_widths(mid : Int32)
      max_widths = @max_widths.each_slice(mid).to_a
      last_size = max_widths.last.size
      max_widths.last.fill(0, last_size, max_widths.first.size - last_size)
      [mid, max_widths.transpose.map! { |x| x.max} ]
    end

    def get_chunks(chunk_size)
      @contents.each_slice(chunk_size)
    end
  end

  class VerticalLayout < Layout
    #private

    def column_widths(mid : Int32)
      chunk_size = (@max_widths.size.to_f / mid).ceil.to_i
      [chunk_size, @max_widths.each_slice(chunk_size).map { |x| x.max }.to_a]
    end

    def get_chunks(chunk_size)
      columns = @contents.each_slice(chunk_size).to_a
      columns.last[chunk_size - 1] = nil if columns.last.size < chunk_size
      columns.transpose
    end
  end
end
