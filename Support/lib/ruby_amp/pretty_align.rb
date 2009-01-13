module RubyAMP::PrettyAlign
  COMMON_SEPARATORS = '[,!~=><\*&\|\/\-\+%]+'
  
  def pretty_align(input, separator_str=nil)
    input ||= ""
    
    separator = case
      when separator_str.is_a?(Regexp)
        separator_str
      when separator_str.to_s.strip =~ /^\/(.+?)\/\w*$/
        $1
      when separator_str
        Regexp.escape(separator_str) unless separator_str.to_s == ''
      end
    
    lines = []
    separators = []
    max_separators = 0
    
    input.split(/\n/, -1).each do |line|
      split_line = line.scan(/(.+?)(#{separator || COMMON_SEPARATORS})(.+?|$)/)
      split_line = [[line]] if split_line.empty?
      split_line[-1][-1] << line[split_line.to_s.size..-1] unless split_line.to_s.size == line.size
      seps           = split_line.map { |e| e[1] }
      max_separators = seps.size if seps.size > max_separators
      lines      << split_line
      separators << seps
    end
    
    0.upto(max_separators - 1) do |token_num|
      next if lines.map { |l| separators[token_num] }.compact.uniq.size > 1
      max_left      = lines.inject(0) { |max, l| l[token_num] && size = l[token_num][0].size; max = size if (size||0) > max; max }
      max_separator = lines.inject(0) { |max, l| l[token_num] && l[token_num][1] && size = l[token_num][1].size; max = size if (size||0) > max; max }
      lines.each do |l|
        if l[token_num]
          left  = l[token_num][0]
          sep   = l[token_num][1]
          right = l[token_num][2]
        end
        format_str = sep == ',' ? "%s%-#{max_left - left.size + 1}s%s" : "%-#{max_left}s%-#{max_separator}s%s"
        l[token_num] = format(format_str, left, sep, right)
      end
    end
    
    lines.map { |l| l.join.rstrip }.join("\n")
  rescue Exception => e
    if ENV['RUBYAMP_TESTING'] == 'true'
      raise e 
    else
      input
    end
  end
end