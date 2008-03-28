# Rdebug runner helpers Tim Harper with Lead Media Partners.
# http://code.google.com/p/productivity-bundle/

require 'rubygems'
require 'ruby-debug'

RUN_FILE = "/tmp/set_breakpoint.rb"
Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])

def init_dbg_breakpoint(commands = "")
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

def cleanup_dbg
  FileUtils.rm_f(RUN_FILE)
end