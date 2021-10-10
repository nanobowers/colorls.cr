require "yaml"

module Colorls
  class Yaml
    @filepath : String

    def initialize(filename : String)
      @user_config_filepath = File.join(Path.home, ".config/colorls/#{filename}")
      @filepath = get_config_file_path(filename)
    end

    # Get current_path (using __DIR__ or __FILE__ is insufficient, because that
    # would reference the dir/file when it was compiled, not at runtime.
    # That said, during dev it's super inconvenient
    def get_config_file_path(filename : String) : String
      exepath = Process.executable_path || PROGRAM_NAME
      if File.exists?(path = File.join(File.dirname(exepath), "./config/yaml/#{filename}"))
        return path
      elsif File.exists?(path = File.join(File.dirname(exepath), "../config/yaml/#{filename}"))
        return path
      elsif File.exists?(path = File.join(__DIR__, "../../config/yaml/#{filename}"))
        return path
      elsif File.exists?(@user_config_filepath)
        return @user_config_filepath
      else
        raise RuntimeError.new("Cannot find path to config file")
      end
    end

    def load(aliase = false) : Hash(String, String)
      yaml = Hash(String, String).from_yaml(File.read(@filepath))
      if @filepath != @user_config_filepath && File.exists?(@user_config_filepath)
        user_config_yaml = Hash(String, String).from_yaml(File.read(@user_config_filepath))
        yaml = yaml.merge(user_config_yaml)
      end
      return yaml
      # :TODO: - but need to understand why this is here..
      # return yaml unless aliase
      # yaml.to_a.map! { |k, v| v.includes?('#') ? [k, v] : [k, v.to_sym] }.to_h
    end
  end
end
