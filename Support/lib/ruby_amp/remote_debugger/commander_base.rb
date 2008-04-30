module RubyAMP
  class RemoteDebugger
    class CommanderBase
      attr_accessor :base
      def initialize(base)
        @base = base
      end
    end
  end
end
