module CurrentThread
  def self.extended(klass)
    klass.mappings ||= {}
    class << klass
      alias :current_without_mapping :current
      alias :current :current_with_mapping
    end unless klass.respond_to?(:current_without_mapping)
  end

  attr_accessor :mappings

  def current_with_mapping
    mappings[current_without_mapping] || current_without_mapping
  end

  def current=(thread)
    garbage_collect
    if thread.nil?
      mappings.delete(Thread.current_without_mapping)
    else
      raise ArgumentError, "expected Thread, got #{thread.class}" unless thread.is_a?(Thread)
      mappings[Thread.current_without_mapping] = thread
    end
  end

  def garbage_collect
    mappings.keys.each do |thread|
      mappings.delete(thread) unless thread.status
    end
  end
end
