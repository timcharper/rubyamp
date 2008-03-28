# TextMate helpers
# Adapted from rspec-bundle (multiple contributors, see http://rspec.info/community/)
# 
# Ruby-debug support added by Tim Harper with Lead Media Partners.
# http://code.google.com/p/productivity-bundle/

require 'rubygems'
gem 'ruby-debug'

class SpecDebugger
  class << self    
    def run(focussed_or_file = :file)
      raise "Invalid argument" unless %w[focussed file].include?(focussed_or_file.to_s)
      
      Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])

      # create a file that will set our breakpoint for us
      File.open("/tmp/set_breakpoint.rb", 'wb')  do |f|
        f.puts <<-EOF
Debugger.settings[:autoeval]=1
Debugger.settings[:autolist]=1
Debugger.add_breakpoint #{ENV['TM_FILEPATH'].to_s.inspect}, #{ENV['TM_LINE_NUMBER']}

require '#{ENV['TM_BUNDLE_SUPPORT']}/lib/spec/mate'
while Debugger.handler.interface.nil?; sleep 0.10; end
Spec::Mate::Runner.new.run_#{focussed_or_file} STDOUT
EOF
      end
    
      fork_delayed_terminal(0.25)
    
      ARGV << "-s"
      ARGV << "/tmp/set_breakpoint.rb"

      load 'rdebug'
    end
    
    def fork_delayed_terminal(seconds_to_wait)    
      Thread.new { 
        sleep seconds_to_wait;

        # fire up an external terminal window for the debug console
        require 'appscript'
        term = Appscript::app("Terminal")
        term.activate
        term.do_script "cd #{ENV['TM_PROJECT_DIRECTORY'].to_s.inspect} && rdebug -c; exit"
      }
      
    end
  end
end