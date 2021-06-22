require "../../src/colorls/monkeys"

describe String do
  describe "#uniq" do
    it "removes all duplicate characters" do
      "abca".uniq.should eq("abc")
    end
  end

  describe String, "#colorize" do
    it "colors a string with red" do
      colorsym = "hello".colorize(:red)
      p! colorsym
      colorstr = "hello".colorize("red")
      p! colorstr
      colorsym.should eq(colorstr)
      ##expect("hello".colorize(:red)).to be == "Rainbow("hello").red
      #p! "hello".colorize(:red)
    end
  end
end
