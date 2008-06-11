module RubyAMP::PrettyAlign
  def pretty_align(separator, input)
    
    if separator
      separator_regexp = Regexp.new(separator.strip.scan(/^\/?(.+?)\/?\w*$/).to_s)

      lines = []

      input.split(/\n/, -1).each do |line|
        if line =~ separator_regexp
          separator = $&.strip
          left, right = line.split(separator_regexp)
          lines << [left.to_s.rstrip, separator, right.to_s.strip]
        else
          lines << [line]
        end
      end

      max_left = lines.max {|a,b| !a[2] ? -1 : a[0].length <=> b[0].length }[0].length
      max_separator = lines.max {|a,b| !a[1] ? -1 : a[1].to_s.length <=> b[1].to_s.length }[1].length

      output = []
      lines.each do |left, separator, right|
        if right
          output << format("%-#{max_left}s %-#{max_separator}s %s", left, separator, right)
        else
          output << left
        end
      end

      output.join("\n")
    else
      input
    end
  end
end