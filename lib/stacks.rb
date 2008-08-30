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
  
  def to_s(verbose=false)
    if verbose
      result = "#{self.class}--(#{name})[#{size}]\n"
      @stack.length.times do |index|
        result << "#{' '*index}--[#{index}] -- #{@stack[index].to_s}\n"
      end
      return result
    else
      result = []
      @stack.each do |element|
        result << element.class.to_s
      end
      return "#{name}[#{size}]: #{result.join(' -- ')}"
    end
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