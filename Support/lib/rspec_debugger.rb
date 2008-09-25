require File.dirname(__FILE__) + "/ruby_amp.rb"

def debug_rspec_story
  if RubyAMP::Config[:rspec_story_bundle_path].nil?
    puts "Can't find rspec-story.tmbundle.  Use 'Edit RubyAMP Global Config' to set the path to where it's installed"
  end
  
  Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
  wrapper_file = RubyAMP::RemoteDebugger.prepare_debug_wrapper(<<-EOF)
    ENV['TM_BUNDLE_SUPPORT'] = RubyAMP::Config[:rspec_story_bundle_path] + "/Support"
    
    require "#{RubyAMP::Config[:rspec_story_bundle_path]}/Support/lib/spec/mate/story/story_helper"
    
    while Debugger.handler.interface.nil?; sleep 0.10; end
    Spec::Mate::Story::StoryHelper.new(ENV['TM_FILEPATH']).run_story
    Runner.story_runner.run_stories
  EOF
  RubyAMP::Launcher.open_controller_terminal

  ARGV << "-s"
  ARGV << wrapper_file

  require 'rubygems'
  require 'ruby-debug'
  load 'rdebug'
end

def debug_rspec(focussed_or_file = :file)
  raise "Invalid argument" unless %w[focussed file].include?(focussed_or_file.to_s)
  if RubyAMP::Config[:rspec_bundle_path].nil?
    puts "Can't find rspec.tmbundle.  Use 'Edit RubyAMP Global Config' to set the path to where it's installed"
  end
  
  Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
  wrapper_file = RubyAMP::RemoteDebugger.prepare_debug_wrapper(<<-EOF)
    ENV['TM_BUNDLE_SUPPORT'] = RubyAMP::Config[:rspec_bundle_path] + "/Support"
    require '#{RubyAMP::Config[:rspec_bundle_path]}/Support/lib/spec/mate'
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
