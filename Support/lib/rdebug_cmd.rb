# Ruby-debug interface helper methods
#
# The following code was derived from Kent Sibilev's ruby-debug bundle.

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
    
  def remote_eval(cmd)
    send_command("e Debugger.eval_from_current_binding(#{cmd.inspect})")
    output
  end
  
  def remote_eval_control_binding(cmd)
    send_command("e send(:eval, #{cmd.inspect})")
    output
  end
  
  def current_frame
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
