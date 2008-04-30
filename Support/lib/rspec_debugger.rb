require File.dirname(__FILE__) + "/ruby_amp.rb"
def debug_rspec(focussed_or_file = :file)
  raise "Invalid argument" unless %w[focussed file].include?(focussed_or_file.to_s)

  Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
  wrapper_file = RubyAMP::RemoteDebugger.prepare_debug_wrapper(<<-EOF)
    require '#{ENV['TM_BUNDLE_SUPPORT']}/lib/spec/mate'
    while Debugger.handler.interface.nil?; sleep 0.10; end
    Spec::Mate::Runner.new.run_#{focussed_or_file} STDOUT
  EOF
  RubyAMP::Launcher.open_controller_terminal

  ARGV << "-s"
  ARGV << wrapper_file

  require 'rubygems'
  require 'ruby-debug'
  load 'rdebug'
end
