require 'socket'
require 'timeout'
module RubyAMP
  class RemoteDebugger
    class DebuggerNotRunning < Exception
      attr_reader :message
      def initialize(message = "The debugger is not running")
        @message = message
      end
    end
    
    class DebuggerNotSane < Exception
      attr_reader :message
      def initialize(message = "The debugger's response was not recognized.")
        @message = message
      end
    end
    
    RUN_FILE = "/tmp/set_breakpoint.rb"

    class << self
      def connect(&block)
        yield(new)
      rescue DebuggerNotRunning => e
        puts e.message
      end

      def prepare_debug_wrapper(commands)
        # create a file that will set our breakpoint for us
        File.open(RUN_FILE, 'wb')  do |f|
          f.puts <<-EOF
            require #{File.join(ENV['TM_BUNDLE_SUPPORT'], '/ext/debugger_extension.rb').inspect}
            Debugger.start
            Debugger.settings[:autoeval]=1
            Debugger.settings[:autolist]=1
            Debugger.add_breakpoint #{ENV['TM_FILEPATH'].to_s.inspect}, #{ENV['TM_LINE_NUMBER']}

            Debugger.wait_for_connection
            #{commands}
          EOF
        end
        RUN_FILE
      end
    end

    attr_reader :socket
  
    def initialize(retries = 1)
      connect
      at_exit { disconnect }
    end

    def connect
      return @socket if @socket
      begin
        @socket = TCPSocket.new('localhost', 8990)

        # test the debugger
        Timeout::timeout(0.5) {
          @first_output = socket.gets
          send_command("e (200 * 3) + 13")
          raise DebuggerNotRunning unless read_output.include?("613")
        }
      rescue Errno::ECONNREFUSED, Timeout::Error
        raise DebuggerNotRunning
      end
    end
  
    def connected?
      @socket ? true : false
    end
  
    def disconnect
      if connected?
        socket.close
        @socket = nil
      end
      true
    end

    def send_command(cmd, msg = nil)
      begin
        socket.puts cmd
        puts msg if msg
      rescue Exception
        puts "Error: #{$!.class}"
      end
    end

    def read_output
      result = ""
      while line = socket.gets
        break if line =~ /^PROMPT/
        result << line
      end

      result
    rescue Exception
      puts "Error: #{$!.class}"
    end
  
    def command(cmd)
      send_command(cmd)
      read_output
    end
  
    def evaluate(cmd, binding = :current, format = :raw)  
      command("e require #{File.join(ENV['TM_BUNDLE_SUPPORT'], '/ext/debugger_extension.rb').inspect}")
      o = command("e Debugger.evaluate(#{cmd.inspect}, :#{binding}, :#{format})")
      eval(o)
    rescue Exception
      o
    end
  
    def current_frame
      evaluate("::Debugger.current_frame", :control)
    end
    
    AUTO_LOAD = {
      :BreakpointCommander  => 'breakpoint_commander.rb',
      :CommanderBase        => 'commander_base.rb',
    }

    def self.const_missing(name)
      @looked_for ||= {}
      raise "Class not found: #{name}" if @looked_for[name]

      return super unless AUTO_LOAD[name]
      @looked_for[name] = true

      require File.join(RUBYAMP_ROOT, "remote_debugger", AUTO_LOAD[name])
      const_get(name)
    end
    
    def breakpoint
      @breakpoint ||= BreakpointCommander.new(self)
    end
  end
end

