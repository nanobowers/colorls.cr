require "../spec_helper"
require "../../src/colorls/layout"

def generate_h_subject(array : Array, width : Int32)
  subject = Colorls::HorizontalLayout.new(array, array.map(&.size), width)
  result = [] of {Array(String), Array(Int32)}
  subject.each_line do |line, maxwid|
    result << {line, maxwid}
  end
  return result
end

describe(Colorls::HorizontalLayout, "#each_line") do
  context "when empty" do
    it "does nothing" do
      result = generate_h_subject(array: [] of String, width: 10)
      result.should be_empty
    end
  end

  context "with one item" do
    it "is on a single line" do
      first = "1234567890"
      result = generate_h_subject(array: [first], width: 11)
      result.should eq [{[first], [first.size]}]
    end
  end
  #
  context "with an item not fitting" do
    it "is on a single column" do
      first = "1234567890"
      result = generate_h_subject(array: [first], width: 1)
      result.should eq [{[first], [first.size]}]
      #      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first], [first.size]])
    end
  end

  context "with two items fitting" do
    it "is on a single line" do
      first = "1234567890"
      result = generate_h_subject(array: [first, "a"], width: 100)
      result.should eq [{[first, "a"], [first.size, 1]}]
    end
  end

  context "with three items but place for two" do
    it "is on two lines" do
      first = "1234567890"
      array = [first, "a", first]
      width = first.size + 1
      result = generate_h_subject(array: array, width: width)
      max_widths = [first.size, 1]
      result.should eq [{[first, "a"], max_widths}, {[first], max_widths}]
    end
  end
end
