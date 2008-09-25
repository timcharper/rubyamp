require File.dirname(__FILE__) + "/../lib/ruby_amp.rb"

module RubyAMP
  def self.unload(const)
    RubyAMP.send(:remove_const, "Config")
    @looked_for.delete(const.to_sym)
  end
end