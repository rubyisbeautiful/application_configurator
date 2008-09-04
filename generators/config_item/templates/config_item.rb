require 'ostruct'
class ConfigItem < ActiveRecord::Base
  validates_presence_of :param_name
  acts_as_nested_set
  
  class <<self
    
    # TODO: replace with something generic
    # def admin(arg)
    #       real_key = "admin_#{arg.to_s}".to_sym
    #       self[real_key]
    #     end
    
    # Dig down to a certain level only and stop
    # the level means what level to display, so if you want only the "top" level keys/items
    # you are actually displaying level 1, as level 0 is the "root" of the nested set
    # returns a Hash of arrays keyed on level
    # example:
    #   ConfigItem.dig(1)
    #     -> { 0 => [top_level_one, top_level_two]>, 1 => [second_level_one] }
    def dig(level=1)
      all.reject{ |foo| foo.level != level }
    end
      
    
    # A convenience method for accessing top-level params by key in a Hash-like way
    # can be chained together
    # if the instance of config_item returned has no children, it will return the param_value
    # if the instance has children, it will return itself in order to allow chaining and other instance methods
    #
    # example (has no children): 
    #   ConfigItem[:foo] -> "bar"
    #
    # example (has children):
    #    ConfigItem[:foo_with_children] -> <#:ConfigItem blah blah>
    #
    # example with chaining:
    #    ConfigItem[:foo_with_children] -> <#:ConfigItem blah blah>
    #    ConfigItem[:foo_with_children][:bar] -> "baz"
    # 
    def [](arg)
      return nil if arg.blank?
      #--
      # really it should be the lowest depth ergo most children that we find, since there is 
      # no column for this (should there be?) have to do max of right-left
      #++
      tmp = find(:all, :conditions => { :param_name => arg.to_s.downcase })
      return {} if tmp.blank?
      return tmp.max{ |a,b| (a.rgt - a.lft) <=> (b.rgt - b.lft) }   
     end
  
    # A convenience method for assigning top-level params in a Hash-like way
    # can be chanined
    # returns the value assigned
    # def []=(arg, val)
    #       foo = find(:first, :conditions => { :param_name => arg.to_s })
    #       raise StandardError.new("Couldn't find a ConfigItem with param_name #{arg}") if foo.blank?
    #       foo.update_attributes(:param_value => val)
    #       # TODO: this has to be updated for the tree stuff
    #       self.load
    #       self.items[arg.to_sym]
    #     end
    
    # Read the application.yml file and create/update db rows
    def read_from_yml(target = File.expand_path(File.dirname(__FILE__) + '/../../config/application.yml'))
      h = YAML.load_file(target)
      raise StandardError.new("Configuration not loaded!") if h.blank?
      linked_list = hash_to_linked_list(h)
      return linked_list_to_nested_set(linked_list)
      # TODO: should call something else to save the result of the previous call -- save_to_db(nested_set)
    end
    alias_method :read_from_yaml, :read_from_yml
    
    def from_hash(target = File.expand_path(File.dirname(__FILE__) + '/../../config/application.yml'))
      h = YAML.load_file(target)
      q = FiloStack.new("open")
      root_os = OpenStruct.new(:obj => nil, :key => 'root', :value => h, :parent => nil)
      q.push root_os
      until q.empty?
        #-- set the current node
        node_os = q.pop
        #-- set the node_ci by creating one from this os
        val = node_os.value.is_a?(String) ? node_os.value : nil
        if node_os.parent.nil?
          node_ci = new(:param_name => node_os.key, :param_value => val, :lft => nil, :rgt => nil, :parent_id => nil)
        else
          node_ci = new(:param_name => node_os.key, :param_value => val)
        end
        node_ci.save!
        #-- set the node_os.obj to the ci we just created
        node_os.obj = node_ci
        #-- add_child it to its parent to set up the left and right columns
        #-- if node_os.parent is nil then we are currently on root
        unless node_os.parent.nil?
          begin
            node_ci.move_to_child_of node_os.parent.obj
          rescue StandardError => e
            raise e
          end
        end
        #-- push any children onto the stack, unless it's a string, then we let it go
        if node_os.value.is_a?(Hash)
          node_os.value.each_key do |child_key|
            if node_os.value[child_key].is_a? Hash
              q.push OpenStruct.new(:obj => nil, :key => child_key, :value => node_os.value[child_key], :parent => node_os)
            else
              child_ci = new(:param_name => child_key, :param_value => node_os.value[child_key])
              child_ci.save!
              child_ci.move_to_child_of node_ci
            end
          end
        end
      end
    end
    
    # pre-Load db rows into the @@items hash
    # def load_from_db
    #      @@items = {}
    #      all.each do |ci|
    #        @@items[ci.param_name.to_sym] = ci.param_value
    #      end
    #    end
    
    # set the specified item to read-only, only partially implemented
    # def read_only(item)
    #      foo = find_by_param_name(item.to_s)
    #      foo.update_attributes(:read_only => true)
    #    end
  
    # Generates a new application.yml based on the values currently in db
    # Creates a timestamped backup from the existing one
    def to_application_yaml
      ConfigItem.root.to_h['root'].to_yaml
    end
    
    # protected
  end
  
  # A convenience method for accessing top-level params by key in a Hash-like way
  # can be chained together
  # if the instance of config_item returned has no children, it will return the param_value
  # if the instance has children, it will return itself in order to allow chaining and other instance methods
  #
  # example (has no children): 
  #   ConfigItem[:foo] -> "bar"
  #
  # example (has children):
  #    ConfigItem[:foo_with_children] -> <#:ConfigItem blah blah>
  #
  # example with chaining:
  #    ConfigItem[:foo_with_children] -> <#:ConfigItem blah blah>
  #    ConfigItem[:foo_with_children][:bar] -> "baz"
  #
  def [](arg)
    logger.debug "looking for #{arg}"
    #-- FKC this took all day to figure out.  nested set uses stupid bracket method instead of attributes
    #-- so check first if it is a netsed set structure column
    if %w( lft rgt parent_id ).include? arg
      return read_attribute(arg)
    end
    return {} if arg.blank?
    tmp = direct_children.detect{ |child| child.param_name == arg.to_s } #(:all, :conditions => { :param_name => arg.to_s })
    return {} if tmp.nil?
    if tmp.all_children_count == 0
      return tmp.param_value
    else
      return tmp
    end
    return {}
  end
  
  
  # # TODO: use real YAML builder stuff
  #   def to_yaml_with_humans(options={})
  #     options[:indent]  ||= 0
  #     "#{param_name}: #{param_value}"
  #   end
  #   alias_method_chain :to_yaml, :humans
  
  # The delta represents the "width" of the nested set node, and can be used to determine if one node fits inside of another
  def delta
    return rgt-lft
  end
  
  def child_of?(other)
    return (other.rgt > rgt) && (other.lft < lft)
  end
  
  def parent_of?(other)
    return (lft < other.lft) && (rgt > other.rgt)
  end
  
  def hash_key
    param_name.downcase.to_sym
  end
  
  def yaml_key
    param_name
  end
  
  def <=>(other)
    case
    when parent_id < other.parent_id
      -1
    when parent_id == other.parent_id
      0
    when parent_id > other.parent_id
      1
    end
  end
  
  def to_h
    os = get
    cs = []
    root = OpenStruct.new(:obj => nil, :key => nil, :value => {}, :parent => nil)
    cs.push(root)
    ci_os = Hash.new(root)
    os.push self
    parent_ci = nil
    until os.empty?
      
      #-- set the current node
      node_ci = os.pop      
      #-- set the ci_os map and any children
      if node_ci.has_children?
        node_os = OpenStruct.new(:obj => node_ci, :key => node_ci.yaml_key, :value => {}, :parent => ci_os[node_ci.parent])
      else
        node_os = OpenStruct.new(:obj => node_ci, :key => node_ci.yaml_key, :value => node_ci.param_value, :parent => ci_os[node_ci.parent])
      end
      parent_ci = node_ci
      
      #-- Map this node
      ci_os[node_ci] = node_os
      #-- push this node onto the cs
      cs << node_os
    end
    
    cs.pop #-- get rid of root?
    cs.each do |os_elem|
      parent = os_elem.parent
      next if parent.nil?
      # puts "os_elem: #{os_elem}"
      parent.value[os_elem.key] = os_elem.value
    end
    # root.value[cs.first.key]=cs.first.value
    return cs.first.value
    #-- finally return our hash
    # ci_os[self].h
  end
  
  def to_s
    "#{param_name}: #{param_value}"
  end
  
  def get(level=99)
    # TODO: do actual levels
    # for now, you get self, direct, or all :)
    # return them in the right order to be stuffed into a FiloStack
    case level
    # 0 means self
    when 0
      return self
    # 1 means direct children
    when 1
      return direct_children
    # above 1 means children of children
    else
      oq = FiloStack.new("open")
      cq = FifoStack.new("closed")
      oq.push(self)
      begin
        current = oq.pop
        if current.has_children?
          cq.push(current)
          current.direct_children.each do |child|
            oq.push(child)
          end
        else
          cq.push(current)
        end
      end until oq.empty?
      return cq
    end
  end
  
  def has_children?
    (delta == 1) ? false : true
  end
  
  # TODO: to_xml
  # def to_xml
  # end
  
  #--
  # TODO:
  # protected
  # def after_save
  #     @@items[param_name.to_sym] = param_value
  #   end
  #   
  #   def before_destroy
  #     @@items.delete(param_name.to_sym)
  #   end
  #==
  
end
