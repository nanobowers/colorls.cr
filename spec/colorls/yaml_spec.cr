require "../../src/colorls/yaml"
require "../support/yaml_sort_checker"

# The purpose of this is to check the included yaml config files
# make sure they are loadable and they are sorted in a specific
# order

describe Colorls::Yaml do

  filenames = {
    file_aliases: KV::Value,
    folder_aliases: KV::Value,
    folders: KV::Key,
    files: KV::Key
  }

  base_directory = "config/yaml"

  filenames.each do |filename, sort_type|
    
    describe filename do
      it "is sorted correctly" do
        checker = YamlSortChecker.new("#{base_directory}/#{filename}.yaml")
        checker.sorted?(sort_type).should be_true
      end
    end
  end
end
