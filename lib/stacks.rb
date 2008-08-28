class Stack
  @stack
  @name
  attr_accessor :name
  
  def initialize(name)
    @stack = []
    @name = name
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
  
  def to_a
    @stack
  end
  
end

class FiloStack < Stack
  
  def push(thing)
    @stack.push(thing)
  end
  
  def pop
    @stack.pop
  end
  
  def current
    if @stack.blank?
      return nil
    else
      return @stack.last
    end
  end
    
end

class FifoStack < Stack
  
  def push(thing)
    @stack.push(thing)
  end
  
  def pop
    @stack.shift
  end
  
  def current
    if @stack.blank?
      return nil
    else
      return @stack.first
    end
  end
  
end