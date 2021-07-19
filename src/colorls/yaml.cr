require "yaml"
module Colorls
  class Yaml
    def initialize(filename : String)
      @filepath = File.join(File.dirname(__FILE__),"../../config/yaml/#{filename}")
      @user_config_filepath = File.join(Path.home, ".config/colorls/#{filename}")
    end

    def load(aliase = false) : Hash(String, String)
      
      yaml = Hash(String, String).from_yaml(File.read(@filepath))
      if File.exists?(@user_config_filepath)
        user_config_yaml = Hash(String, String).from_yaml(File.read(@user_config_filepath))
        yaml = yaml.merge(user_config_yaml)
      end
      return yaml
      # :TODO: - but need to understand why this is here..
      #return yaml unless aliase
      #yaml.to_a.map! { |k, v| v.includes?('#') ? [k, v] : [k, v.to_sym] }.to_h
    end

  end
end
