require "yaml"
module Colorls
  class Yaml
    def initialize(filename : String)
      @filepath = File.join(File.dirname(__FILE__),"../../lib/yaml/#{filename}")
      @user_config_filepath = File.join(Path.home, ".config/colorls/#{filename}")
    end

    def load(aliase = false) : Hash(YAML::Any, YAML::Any)
      yaml = read_file(@filepath).as_h
      if File.exists?(@user_config_filepath)
        user_config_yaml = read_file(@user_config_filepath).as_h
        yaml = yaml.merge(user_config_yaml)
      end
      return yaml
      #TODO
      #return yaml unless aliase
      #yaml.to_a.map! { |k, v| v.includes?('#') ? [k, v] : [k, v.to_sym] }.to_h
    end

    def read_file(filepath)
      File.open(filepath) do |file|
        YAML.parse(file)
      end
      #::YAML.load(File.read(filepath, encoding: "UTF_8")).transform_keys!(&:to_sym)
    end
  end
end
