module RubyAMP
  class RemoteDebugger
    class BreakpointCommander < CommanderBase
      def list
        base.evaluate("Debugger.breakpoints.map{|b| {:id => b.id, :source => b.source, :line => b.pos} }", :control).map do |bp_options|
          Breakpoint.new(base, self, bp_options)
        end
      end
      
      def delete_all
        base.evaluate <<-EOF, :control
          breakpoint_ids = Debugger.breakpoints.map { |b| b.id }
          begin
            breakpoint_ids.each { |b_id| Debugger.remove_breakpoint(b_id) }
            breakpoint_ids.length
          rescue
            0
          end
        EOF
      end
      
      def add(source, line)
        base.evaluate <<-EOF, :control
          bp = Debugger.add_breakpoint #{ENV['TM_FILEPATH'].to_s.inspect}, #{ENV['TM_LINE_NUMBER']}
          bp ? true : false
        EOF
      end
    end
    
    class Breakpoint
      attr_accessor :source, :line, :id
      
      def initialize(base, parent, options = {})
        self.id = options[:id]
        self.source = options[:source]
        self.line = options[:line]
      end
    end
  end
end