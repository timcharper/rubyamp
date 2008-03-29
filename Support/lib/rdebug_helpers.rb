# Rdebug runner helpers Tim Harper with Lead Media Partners.
# http://code.google.com/p/productivity-bundle/

require 'rubygems'
require 'ruby-debug'
require 'appscript'

RUN_FILE = "/tmp/set_breakpoint.rb"
Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])

def init_debug_run_file(commands = "")
  # create a file that will set our breakpoint for us
  File.open(RUN_FILE, 'wb')  do |f|
      f.puts <<-EOF
Debugger.start
Debugger.settings[:autoeval]=1
Debugger.settings[:autolist]=1
Debugger.add_breakpoint #{ENV['TM_FILEPATH'].to_s.inspect}, #{ENV['TM_LINE_NUMBER']}
while Debugger.handler.interface.nil?; sleep 0.10; end
#{commands}
    EOF
  end
end

def launch_dbg_controller(seconds_to_wait = 0.01)    
  Thread.new { 
    sleep seconds_to_wait;

    # fire up an external terminal window for the debug console
    term = Appscript::app("Terminal")
    term.activate
    term.do_script "cd #{ENV['TM_PROJECT_DIRECTORY'].to_s.inspect} && rdebug -c; exit"
  }
end

def launch_dbg_instance
  term = Appscript::app("Terminal")
  term.activate
  term.do_script "cd #{ENV['TM_PROJECT_DIRECTORY'].to_s.inspect} && rdebug -s #{RUN_FILE}; exit"

  sleep 0.25
end

def debug_rspec(focussed_or_file = :file)
  raise "Invalid argument" unless %w[focussed file].include?(focussed_or_file.to_s)
  
  Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
  init_debug_run_file <<-EOF
require '#{ENV['TM_BUNDLE_SUPPORT']}/lib/spec/mate'
while Debugger.handler.interface.nil?; sleep 0.10; end
Spec::Mate::Runner.new.run_#{focussed_or_file} STDOUT
EOF
  launch_dbg_controller(0.25)

  ARGV << "-s"
  ARGV << RUN_FILE

  load 'rdebug'
end

def cleanup_dbg
  FileUtils.rm_f(RUN_FILE)
end