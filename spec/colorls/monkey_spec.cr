require "../../src/colorls/monkeys"

describe String do
  
  describe "#uniq" do
    it "removes all duplicate characters" do
      "abca".uniq.should eq("abc")
    end
  end

  describe "#colorize" do
    it "colors a string with red" do
      colorsym = "hello".colorize(:red)
      colorstr = "hello".colorize("red")
      colorsym.should eq(colorstr)
    end
  end
  
end
