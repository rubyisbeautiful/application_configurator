class FiloStack
  @stack
  
  def initialize
    @stack = []
  end
  
  def push(thing)
    @stack.push(thing)
  end
  
  def pop
    @stack.pop
  end
  
  def empty?
    @stack.blank?
  end
  
  def current
    if @stack.blank?
      return nil
    else
      return @stack.last
    end
  end
end

module HashExtension  
  def to_flat_a
    tmp = to_a.flatten
    while tmp.any?{|foo|foo.is_a? Hash}
      elem = tmp.detect{|foo| foo.is_a? Hash}
      tmp.delete(elem)
      tmp.push(elem.to_a.flatten)
      tmp.flatten!
    end
    return tmp
  end
end
  