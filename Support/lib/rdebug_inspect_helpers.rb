require "#{ENV["TM_BUNDLE_SUPPORT"]}/lib/ruby_tm_helpers.rb"
require "#{ENV["TM_BUNDLE_SUPPORT"]}/lib/rdebug_cmd.rb"

class RDebugInspect
  attr_accessor :what
  
  def initialize(params = {})
    self.what = params[:what]
    
    if self.what.nil?
      self.what = tm_expanded_selection(
        :forward => /[a-z0-9_]*[\?\!]{0,1}/i,
        :backward => /[a-z0-9._:]*[@$]*/i
      ) 
    end
    
    halt_if_debug_not_running
  end
  
  def dcmd
    @dcmd ||= DebuggerCmd.new
  end
  
  def halt_if_debug_not_running
    dcmd
    exit if DebuggerCmd.not_running
  end
  
  # we have to do some voodoo to find the current contexts binding, since when we're connecting with this method it doesn't give it to us
  def get_var_expr
    "::Object.send(:eval, #{what.to_s.inspect}, ::Object::Debugger.current_binding)"
  end
  
  def remote_evaluate(cmd)  
    o = dcmd.remote_evaluate(cmd)
    
    if o.nil? || (line = o.split("\n").first).nil? || line.match(/^[a-z:]+ Exception: /i)
      return o
    else
      eval o
    end
  end
  
  def inspect_as_string
    remote_evaluate("#{get_var_expr}.to_s")
  end
  
  def inspect_as_pp
    remote_evaluate "::Object.require('pp'); ::Object::PP.pp(#{get_var_expr}, __tmp_output__=''); __tmp_output__"
  end
  
  def inspect_as_yaml
    remote_evaluate "::Object.require 'yaml'; (#{get_var_expr}).to_yaml"
  end
end