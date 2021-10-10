require "yaml"

enum KV
  Key
  Value
end

# Check Yaml if Alphabetically sorted
class YamlSortChecker
  class NotSortedError < RuntimeError
  end

  @yaml : YAML::Any # set type

  def initialize(filename : String)
    @yaml = YAML.parse("") # to make typing be happy, must be a better way.
    File.open(filename) do |file|
      @yaml = YAML.parse(file)
    end
  end

  def sorted?(kvtype : KV) : Bool
    case kvtype
    when KV::Key   then key_sorted?
    when KV::Value then value_sorted?
    else
      false
    end
  end

  private def key_sorted?
    keys = @yaml.as_h.keys.map { |x| x.to_s.downcase }
    sorted_keys = keys.sort
    return sorted_keys == keys
  end

  private def value_sorted?
    vals = @yaml.as_h.values.map { |x| x.to_s.downcase }
    sorted_vals = vals.sort
    return sorted_vals == vals
  end
end
