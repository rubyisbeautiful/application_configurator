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
  