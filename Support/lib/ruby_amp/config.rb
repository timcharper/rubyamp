require 'yaml'
module RubyAMP::Config
  extend self
  DEFAULTS = {
    "server_port" => 3000,
    "rspec_story_bundle_path" => lambda { Dir.entries(RubyAMP::LIB_ROOT + "/../../../").grep(/rspec.*story.*\.tmbundle/i).first },
  }.freeze
  
  CONFIG_PATHS = {
    :global => RubyAMP::LIB_ROOT + "/../../config.yml",
    :local => RubyAMP.project_path + "/.rubyamp-config.yml"
  }.freeze
  
  def config_data(local_or_global)
    @config_data ||= {
      
    }
  end
  
  def create_config(local_or_global)
    return false if File.exist?(CONFIG_PATHS[local_or_global])
    cfg = config(local_or_global)
    DEFAULTS.keys.each { |k| cfg[k] ||= nil }
    store_config(local_or_global)
  end
  
  def [](key, level = nil)
    key = key.to_s
    if level
      config(level)[key]
    else
      self[key, :local] || self[key, :global] || self[key, :default]
    end
  end
  
  def []=(*args)
    value = args.pop
    key, level = args[0].to_s, args[1] || :global
    raise ArgumentError, "You can't set defaults" if level == :default
    config(level)[key] = value
  end
  
  def config(level = :default)
    case level
    when :local, :global
      @config ||= {}
      @config[level] ||= File.exist?(CONFIG_PATHS[level]) ? YAML.load_file(CONFIG_PATHS[level]) : {}
    when :default
      defaults
    else
      raise ArgumentError, "invalid"
    end
  end
  
  def store_config(local_or_global = nil)
    data = config(local_or_global).to_yaml
    File.open(CONFIG_PATHS[local_or_global], "wb") { |f| f << data }
  end
  
  private
    def defaults
      @defaults ||= (
        @defaults = DEFAULTS.dup
        @defaults.keys.each do |key|
          @defaults[key] = @defaults[key].call if @defaults[key].is_a?(Proc)
        end
        @defaults
      )
    end
end