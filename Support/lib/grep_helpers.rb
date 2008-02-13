require 'cgi'
require 'rubygems'
require 'appscript'
require "#{ENV['TM_BUNDLE_SUPPORT']}/lib/ruby_tm_helpers.rb"

# Html output code by Henrik Nyh <http://henrik.nyh.se> 2007-06-26
# Free to modify and redistribute with credit.
#
# Improved upon by Tim Harper with Lead Media Partners.
# http://code.google.com/p/productivity-bundle/

%w{ui web_preview escape}.each { |lib| require "%s/lib/%s" % [ENV['TM_SUPPORT_PATH'], lib] }

module GrepperDisplayHelpers
  def ellipsize_path(path)
    path.sub(/^(.{30})(.{10,})(.{30})$/) { "#$1⋯#$3" }
  end
  
  def short_path(path, paths_to_display = 2)
    path.split("/")[(-1 - paths_to_display)..(-1)] * "/"
  end
end

class Grepper
  include GrepperDisplayHelpers
  
  attr_accessor :name, :exclude_files
  attr_reader :query, :include_files
  attr_accessor :fixed_strings
  attr_writer :query_highlight_regexp
  attr_accessor :case_sensitive
  
  def query_highlight_regexp
    @query_highlight_regexp || query_regexp
  end
  
  def query=(regexp)
    @query_regexp = nil
    regexp = regexp.inspect if regexp.is_a?(Regexp)
    if /^\/(.+)\/([i]*)$/.match(regexp)
      @query = $1
      self.case_sensitive = $2 != "i"
      # puts "<div>$2 = #{$2} #{self.case_sensitive}</div>"
      self.fixed_strings = false
    else
      self.fixed_strings = true
      @query = regexp
      self.case_sensitive = true
    end
  end
  
  def query_regexp
    @query_regexp ||= begin
      o = 
        if fixed_strings
          Regexp.escape(query).gsub("/", '\/')
        else
          query
        end
      Regexp.new(o, case_sensitive ? nil : Regexp::IGNORECASE)
    end
  end
  
  attr_writer :title
  
  def title
    @title || %!Searching for #{ query_regexp.inspect }!
  end
  
  
  def parse_regexp(regexp)
    self.query = regexp
    # puts command
  end
  
  def initialize(name, options = {})
    self.name = name
    self.fixed_strings = options[:fixed_strings]
    self.query = options[:query]
    self.exclude_files = [options[:exclude_files] || %w[*.log *.log*]].compact.flatten
    @include_files = [options[:include_files]].compact.flatten || []
    self.case_sensitive = true
  end

  def bail(message)
    puts <<-HTML
      <h2>#{ message }</h2>
    HTML
    puts html_footer
    exit
  end
  
  def directory
    ENV['TM_PROJECT_DIRECTORY'] || ( ENV['TM_FILEPATH'] && File.dirname(ENV['TM_FILEPATH']) )
  end
  
  def abort
    puts "Search aborted"
    exit_show_tool_tip
  end
  
  def matches
    return @matches if @matches
    
    @matches = []
    IO.popen(command) do |pipe|
      last_path = path = i = nil
      pipe.each_with_index do |line, i|
        if line =~ /^(Binary file )(.*?) matches/
          prefix, file = $1, $2
          path = directory + file[1..-1]
          @matches << {
            :binary_file => true,
            :prefix => prefix,
            :file => file,
            :path => path
          }
          next
        end

        line.gsub!(/^([^:]+):(\d+):(.*)$/) do
          relative_path, line_number, content = $1, $2, $3.strip
          path = directory + relative_path[1..-1]
          @matches << {
            :relative_path => relative_path,
            :line_number => line_number,
            :content => content,
            :path => path
          }
        end
        last_path = path
      end
    end
    @matches
  end
  
  def tm_goto_match(m)
    tm_open(m[:path], :line => m[:line_number])
  end
  
  def run(&block)
    bail("Not in a saved file") unless directory
    
    yield
    
    abort unless query
    
    if matches.length == 1
      tm_goto_match(matches.first)
      exit_discard
    end
    
    if matches.length == 0
      puts "No results - #{title}"
      exit_show_tool_tip
    end
    # matches
    
    display
  end
  
  def command
    include_param = include_files.map{|f| "--include='#{f}'"} * " "
    fixed_strings_param = fixed_strings ? "--fixed-strings" : "-E"
    case_sensitive_param = case_sensitive ? "" : "--ignore-case"  
    exclude_param = exclude_files.map{|f| "--exclude='#{f}'"} * " "
    find_command = Finder.new(".").command
    command = 
      %{cd "#{directory}"; #{find_command} | xargs -0 grep -nr #{case_sensitive_param} #{fixed_strings_param} #{exclude_param} #{include_param} #{e_sh query}}
  end
  
  def display
    puts "implement me!"
  end
end

class Finder
  attr_accessor :path
  
  def initialize(path=".")
    self.path = path
  end
  
  def command
    "find #{path} \\( -path '*/.svn' -or -path '*/vendor/rails' \\) -prune -or -type f -print0"
  end
  
  def results
    @results = []
    
    IO.popen(command) do |pipe|
      pipe.read.split("\000").each do |line|
        @results << line
      end
    end
    @results
  end
end

class GrepperMenu < Grepper
  def display
    match_index = TextMate::UI.menu(matches.map{|m| "#{short_path(m[:path])}:#{m[:line_number]} - #{m[:content]}"})
    exit_discard if match_index.nil?
    
    tm_goto_match(matches[match_index])
    exit_show_tool_tip
  end
end

class GrepperHTML < Grepper
  
  def escape(string)
    CGI.escapeHTML(string)
  end
  
  # sadly... this causes textmate to crash.  Can't do this.
  def html_close_tm_window
    <<-EOF
      <script type="text/javascript">
        setTimeout(function() {
          TextMate.close();
        }, 1000);
      </script>
    EOF
  end
  
  def display
    
    puts html_for_head
    puts html_for_body
    puts <<-HTML
      <h2>#{escape title}</h2>
      <table>
    HTML
    
    last_path = path = i = nil
    matches.each_with_index do |match, i|

      if match[:binary_file]
        puts <<-HTML
          <tr class="binary #{ 'odd' unless i%2==0 }">
            <td>
              #{ prefix }
              <a href="javascript:reveal_file('#{ escape(match[:path]) }')" title="#{ escape(match[:path]) }">#{ ellipsize_path(match[:file]) }</a>
            </td>
            <td></td>
          </tr>
          #{ html_for_resize_table if i%100==0 }
        HTML
        next
      end
      
      url = "txmt://open/?url=file://#{match[:path]}&line=#{match[:line_number]}"
      highlighted_content = escape(match[:content]).
                  # Highlight keywords
                  gsub(query_highlight_regexp) { %{<strong class="keyword">#$&</strong>} }.
                  # Ellipsize before, between and after keywords
                  gsub(%r{(^[^<]{25}|</strong>[^<]{15})([^<]{20,})([^<]{15}<strong|[^<]{25}$)}) do
                    %{#$1<span class="ellipsis" title="#{escape($2)}">⋯</span>#$3}
                  end
      puts <<-HTML
        <tr class="#{ 'odd' unless i%2==0 } #{ 'newFile' if (match[:path] != last_path) }">
          <td>
            <a href="#{ url }" title="#{ "%s:%s" % [match[:path], match[:line_number]] }">
              #{ "%s:%s" % [ellipsize_path(match[:relative_path]), match[:line_number]] }
            </a>
          </td>
          <td>#{ highlighted_content }</td>
        </tr>
      HTML
      last_path = path
    end
    if i
      # A paragraph inside the table ends up at the top even though it's output
      # at the end. Something of a hack :)
      i += 1
      puts <<-HTML
        <p>#{i} matching line#{i==1 ? '' : 's'}:</p>
        #{html_for_resize_table}
      HTML
    else
      puts <<-HTML
        <tr id="empty"><td colspan="2">No results.</td></tr>
      HTML
    end
    
    puts <<-HTML
    </table>
    HTML
    
    html_footer
    
    puts html_close_tm_window
    
    exit_show_html
  end
  
  def html_for_head
    html_head(
      :window_title => name,
      :page_title   => name,
      :sub_title    => directory || "Error",
      :html_head    => name
    )
  end
  
  def html_for_resize_table
    <<-HTML
      <script type="text/javascript">
        resizeTableToFit();
      </script>
    HTML
  end
  
  def html_for_body
    <<-HTML
      <style type="text/css">
        table { font-size:0.9em; border-collapse:collapse; border-bottom:1px solid #555; }
        h2 { font-size:1.3em; }
        tr { background:#FFF; }
        tr.odd { background:#EEE; }
        td { vertical-align:top; white-space:nowrap; padding:0.4em 1em; color:#000 !important; }
        tr td:first-child { text-align:right; padding-right:1.5em; }
        td a { color:#00F !important; }
        tr.binary { background:#E8AFA8; }
        tr.binary.odd { background:#E0A7A2; }
        tr#empty { border-bottom:1px solid #FFF; }
        tr#empty td { text-align:center; }
        tr.newFile, tr.binary { border-top:1px solid #555; }
        .keyword { font-weight:bold; background:#F6D73A; margin:0 0.1em; }
        .ellipsis { color:#777; margin:0 0.5em; }
      </style>
      <script type="text/javascript">
        function reveal_file(path) {
          const quote = '"';
          const command = "osascript -e ' tell app "+quote+"Finder"+quote+"' " +
                            " -e 'reveal (POSIX file " +quote+path+quote + ")' " +
                            " -e 'activate' " + 
                          " -e 'end' ";
          TextMate.system(command, null);
        }

      function findPos(obj) {
        var curleft = curtop = 0;
        if (obj.offsetParent) {
          curleft = obj.offsetLeft
          curtop = obj.offsetTop
          while (obj = obj.offsetParent) {
            curleft += obj.offsetLeft
            curtop += obj.offsetTop
          }
        }
        return {left: curleft, top: curtop};
      }

      function resizeTableToFit() {
        var table = document.getElementsByTagName("table")[0];
        const minWidth = 450, minHeight = 250;

        var pos = findPos(table);
        var tableFitWidth = table.offsetWidth + pos.left * 2;
        var tableFitHeight = table.offsetHeight + pos.top + 50;
        var screenFitWidth = screen.width - 150;
        var screenFitHeight = screen.height - 150;

        var setWidth = tableFitWidth > screenFitWidth ? screenFitWidth : tableFitWidth;
        var setHeight = tableFitHeight > screenFitHeight ? screenFitHeight : tableFitHeight;  
        setWidth = setWidth < minWidth ? minWidth : setWidth;
        setHeight = setHeight < minHeight ? minHeight : setHeight;

        window.resizeTo(setWidth, setHeight);
      }

      </script>
    HTML
  end
  
end