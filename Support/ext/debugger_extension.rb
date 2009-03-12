# monkey patch the RemoteInterface so we can access the context
module Debugger
  class << self
    attr_accessor :context
    attr_writer :current_frame
    
    def current_frame
      @current_frame ||= 0
    end
    
    def current_binding
      context.frame_binding(current_frame)
    end
    
    def context
      @context ||= contexts.first
    end
    
    def eval_from_current_binding(cmd)
      eval(cmd, current_binding)
    end
    
    def evaluate(cmd, binding = :current, format = :raw)
      result = Kernel.eval(cmd, (binding == :current) ? current_binding : Kernel.binding)
      case format
      when :pp
        require('pp')
        ::PP.pp(result, output='') rescue result.inspect
        output
      when :yaml
        require('yaml')
        result.to_yaml
      when :string
        result.to_s
      when :raw
        result
      end
    rescue Exception => e
      <<-EOF
Error evaluating #{cmd.inspect}:
#{e.to_s}
#{e.backtrace * "\n"}
EOF
    end
    
    def wait_for_connection
      while Debugger.handler.interface.nil?; sleep 0.10; end
    end
  end
  
  class CommandProcessor # :nodoc:
    alias :process_commands_without_hook :process_commands
    def process_commands(context, file, line)
      Debugger.context = context
      process_commands_without_hook(context, file, line)
    end
  end
end
