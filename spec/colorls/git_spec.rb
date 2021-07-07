require "../../src/colorls/git"
#require 'spec_helper'

describe Colorls::Git do

  before(:all) do
    `echo` # initialize $? / $CHILD_STATUS
    expect($?).to be_success
  end

  context "with file in repository root" do
    it "returns `M`" do
      allow(subject).to receive(:git_prefix).with("/repo/").and_return(["", true])
      allow(subject).to receive(:git_subdir_status).and_yield("M", "foo.txt")

      expect(subject.status("/repo/")).to include("foo.txt" => Set["M"])
    end

    it "returns `??`" do
      allow(subject).to receive(:git_prefix).with("/repo/").and_return(["", true])
      allow(subject).to receive(:git_subdir_status).and_yield("??", "foo.txt")

      expect(subject.status("/repo/")).to include("foo.txt" => Set["??"])
    end
  end

  context "with file in subdir" do
    it "returns `M` for subdir" do
      allow(subject).to receive(:git_prefix).with("/repo/").and_return(["", true])
      allow(subject).to receive(:git_subdir_status).and_yield("M", "subdir/foo.txt")

      expect(subject.status("/repo/")).to include("subdir" => Set["M"])
    end

    it "returns `M` and `D` for subdir" do
      allow(subject).to receive(:git_prefix).with("/repo/").and_return(["", true])
      allow(subject).to receive(:git_subdir_status).and_yield("M", "subdir/foo.txt").and_yield("D", "subdir/other.c")

      expect(subject.status("/repo/")).to include("subdir" => Set["M", "D"])
    end
  end
  
end
