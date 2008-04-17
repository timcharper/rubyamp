require 'rubygems'
$:.unshift "#{ENV['TM_BUNDLE_SUPPORT']}/lib"
require "ruby_tm_helpers"
require "grep_helpers"
# DEMO TARGET: require 'hpricot'
# DEMO TARGET: require 'ruby-debug'
# DEMO TARGET: require 'map_by_method'

module GoToExternal
  extend self
  # Returns the path of the project or file that best
  # matches the context of where the cursor/caret is currently
  def run
    target_gem = target_term #ENV['TM_CURRENT_WORD']
    if gem_spec = Gem.source_index.find_name(target_gem).last
    	gem_path = gem_spec.full_gem_path
    	tm_open gem_path
    else
    	puts "No RubyGem with name '#{target_gem}'"
    end
  end

  def target_term
    filepath = tm_expanded_selection(
      :backward => /[\w\/.-]+/,
      :forward =>  /[\w\/.-]+/
    ).strip
  end
end