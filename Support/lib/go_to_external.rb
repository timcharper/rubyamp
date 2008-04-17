require 'rubygems'
$:.unshift "#{ENV['TM_BUNDLE_SUPPORT']}/lib"
require "grep_helpers"
# DEMO TARGET: require 'hpricot'

class GoToExternal
  # Returns the path of the project or file that best
  # matches the context of where the cursor/caret is currently
  def self.run
    target_gem = ENV['TM_CURRENT_WORD']
    if gem_spec = Gem.source_index.find_name(target_gem).last
    	gem_path = gem_spec.full_gem_path 
    	%x{open -a TextMate #{gem_path}}
    else
    	puts "No RubyGem with name '#{target_gem}'"
    end
  end
end