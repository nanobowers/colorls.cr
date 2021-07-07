require "../spec_helper"
require "../../src/colorls/layout"

def generate_v_subject(array : Array, width : Int32) : Colorls::VerticalLayout
  Colorls::VerticalLayout.new(array,  width)
  # array.map(&.size),
end

describe(Colorls::VerticalLayout, "#each_line") do

  context "when empty" do
    it "does nothing" do
      subject = generate_v_subject(array: [] of String, width: 10)
      subject.each_line
      #expect { |b| subject.each_line(&b) }.not_to yield_control
    end
  end

  context "with one item" do
    it "is on a single line" do
      first = "1234567890"
      subject = generate_v_subject(array: [first], width: 11)
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first], [first.size]])
    end
  end

  context "with an item not fitting" do
    it "is on a single column" do
      first = "1234567890"
      subject = generate_v_subject(array: [first], width: 1)
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first], [first.size]])
    end
  end

  context "with two items fitting" do
    it "is on a single line" do
      first = "1234567890"
      subject = generate_v_subject(array: [first, "a"], width: 100)
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first, "a"], [first.size, 1]])
    end
  end

  context "with three items but place for two" do
    it "is on two lines" do
    first = "1234567890"

    let(:array) { [first, "a", first] }
    let(:width) { first.size * 2 }

      max_widths = [first.size, first.size]
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first, first], max_widths], [["a"], max_widths])
    end
  end
end
