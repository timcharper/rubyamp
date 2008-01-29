# Ruby-debug interface helper methods
#
# Code adapted from ruby-debug bundle by Kent Sibilev
# http://www.datanoise.com/articles/2006/8/27/control-debugger-from-textmate
#
# Improved upon by Tim Harper with Lead Media Partners.
# http://code.google.com/p/productivity-bundle/

require 'socket'

class DebuggerCmd
  class << self
    attr_reader :not_running
    def socket(retries=1)
      tryCount = 1
      return if @not_running
      
      begin
        tryCount += 1
        @socket ||= TCPSocket.new('localhost', 8990)
      rescue Errno::ECONNREFUSED        
        sleep(0.10) and retry if tryCount < retries
        
        puts "Debugger is not running."
        @not_running = true
      end
    end
  end
  
  def initialize(retries = 1)
    socket(retries)
  end
  
  def socket(retries = 1)
    self.class.socket(retries)
  end
  
  def send_command(cmd, msg = nil)
    return if self.class.not_running
    begin
      @first_output ||= socket.gets
      socket.puts cmd
      puts msg if msg
    rescue Exception
      puts "Error: #{$!.class}"
    end
  end

  def output
    return if self.class.not_running
    result = ""
    while line = socket.gets
      break if line =~ /^PROMPT/
      result << line
    end
    result
  rescue Exception
    puts "Error: #{$!.class}"
  end
  
  def print_output
    return if self.class.not_running
    puts output
  end
  
  def set_friendly_mode
    send_command "set autoeval", "Auto eval mode set"
    output
    send_command "set autolist", "Auto list mode set"
    output
  end
  
  # this is such a hack I'm almost ashamed of it!  There's got to be a better way (but, it turns out it works pretty reliably)
  def install_current_context
    current_context = <<-EOF

  class << self
    attr_writer :current_frame
    
    def current_frame
      @current_frame ||= 0
    end
    
    def current_binding
      current_context.frame_binding(current_frame)
    end
    
    def current_context
      classes = contexts.map{|c| eval("self.class.to_s", c.frame_binding(0)) rescue nil}
      idx = 
        if classes.include?("Mongrel::Rails::RailsConfigurator")
          -4
        else
          -3
        end
      contexts[idx]
    end
  
    def eval_from_current_binding(cmd)
      eval(cmd, current_binding)
    end
  end
EOF
    send_command("e Debugger.send(:class_eval, #{current_context.inspect})")
    output
  end
  
  alias install_extension install_current_context
  def remote_eval(cmd)
    install_current_context    
    send_command("e Debugger.eval_from_current_binding(#{cmd.inspect})")
    output
  end
  
  def remote_eval_control_binding(cmd)
    install_current_context    
    send_command("e send(:eval, #{cmd.inspect})")
    output
  end
  
  def current_frame
    install_current_context
    send_command("e Debugger.current_frame")
    output.to_i
  end
  
  alias remote_evaluate remote_eval
end

at_exit do
  begin
    DebuggerCmd.socket.close if DebuggerCmd.socket
  rescue Exception
  end
end
