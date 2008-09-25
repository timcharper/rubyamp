require 'rubygems'
require 'appscript'

module RubyAMP
  module Launcher
    def open_controller_terminal    
      term = Appscript::app("Terminal")
      term.activate
      term.do_script "cd #{ENV['TM_PROJECT_DIRECTORY'].to_s.inspect} && sleep 0.25 && rdebug -c; exit"
    end

    def open_debug_process_in_terminal(file_to_run, args = "")
      term = Appscript::app("Terminal")
      term.activate
      term.do_script "cd #{ENV['TM_PROJECT_DIRECTORY'].to_s.inspect} && rdebug -s #{file_to_run} -- #{args}; exit"
    end

    def open_debug_process_in_html_dialog(file_to_run)
      require 'ruby-debug'
      term = Appscript::app("Terminal")
      term.activate
      term.do_script "cd #{ENV['TM_PROJECT_DIRECTORY'].to_s.inspect} && rdebug -s #{file_to_run}; exit"
    end
    extend self
  end
end