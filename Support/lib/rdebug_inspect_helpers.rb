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
    "send(:eval, #{what.to_s.inspect}, Debugger.current_binding)"
  end
  
  def remote_evaluate(cmd)  
    o = dcmd.remote_evaluate(cmd)
    
    if o.match(/^[a-z:]+Error Exception: /i)
      puts "Couldnt evaluate '#{what}'\n\n#{o}"
      exit_show_tool_tip
    end
    
    # remove extra quotes and stuff by using eval
    eval(o)
  rescue
    
  end
  
  def inspect_as_string
    remote_evaluate("#{get_var_expr}.to_s")
  end
  
  def inspect_as_pp
    remote_evaluate "require 'pp'; PP.pp(#{get_var_expr}, tmp_output=''); tmp_output"
  end
  
  def inspect_as_yaml
    remote_evaluate "require 'yaml'; (#{get_var_expr}).to_yaml"
  end
end