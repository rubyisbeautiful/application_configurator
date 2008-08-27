class FiloStack
  @stack
  @name
  attr_accessor :name
  
  def initialize(name)
    @stack = []
    @name = name
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
  
  def size
    @stack.length
  end
  
  def to_s
    result = []
    @stack.each do |stack|
      result << stack.class.to_s
    end
    return "#{name}[#{size}]: #{result.join(' -- ')}"
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
  