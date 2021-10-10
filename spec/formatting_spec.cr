require "./spec_helper"
require "../src/colorls/format"

describe Colorls::Format do
  it "formats small files" do
    Colorls::Format.filesize_string(0).should eq "   0 B  "
    Colorls::Format.filesize_string(1).should eq "   1 B  "
    Colorls::Format.filesize_string(999).should eq " 999 B  "
    Colorls::Format.filesize_string(1023).should eq "1023 B  "
    Colorls::Format.filesize_string(1024).should eq " 1.0 KiB"
  end
  it "formats medium sized files" do
    Colorls::Format.filesize_string(1554).should eq " 1.5 KiB"
    Colorls::Format.filesize_string(4096).should eq " 4.0 KiB"
    Colorls::Format.filesize_string(112181).should eq " 110 KiB"
    Colorls::Format.filesize_string(1009984).should eq " 986 KiB"
    Colorls::Format.filesize_string(1048575).should eq "1024 KiB"
  end

  it "formats large sized files" do
    Colorls::Format.filesize_string(1048576).should eq " 1.0 MiB"
    Colorls::Format.filesize_string(1107080).should eq " 1.1 MiB"
    Colorls::Format.filesize_string((9.9*(1024**2)).to_i64).should eq " 9.9 MiB"
    Colorls::Format.filesize_string((57*(1024**2)).to_i64).should eq "  57 MiB"
    Colorls::Format.filesize_string((777*(1024**2)).to_i64).should eq " 777 MiB"
  end

  it "formats super large sized files" do
    Colorls::Format.filesize_string(4290000000).should eq " 4.0 GiB"
    Colorls::Format.filesize_string(4390000000000).should eq " 4.0 TiB"
    Colorls::Format.filesize_string(((1024.to_i64**5)*55)).should eq "  55 PiB"
  end
end
