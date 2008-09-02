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
      result = {}
      level.times do |key|
        result[key+1] = []
      end
      parents = find(:all, :conditions => { :lft => 1 })
      #-- there should only be one root, but can we count on it?
      #-- level should now be greater than 0 since we've gotten roots
      oq = FifoStack.new("open")
      # cq = FifoStack.new("closed")
      #-- load the q with the root nodes
      oq.push parents
      #-- start iterating
      level.times do |key|
        #-- pop an array off
        current = oq.pop
        #-- iterate through the array, adding each to the results hash by level and pushing any children onto the open q
        current.each do |node|
          result[key+1] = node.direct_children
          oq.push(node.direct_children)
        end
      end
      #-- return the hash, keyed by level
      return result
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
      return nil if tmp.blank?
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
      linked_list_to_nested_set(linked_list)
      # TODO: should call something else to save the result of the previous call -- save_to_db(nested_set)
    end
    alias_method :read_from_yaml, :read_from_yml
        
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
    
    # Return the root node of all nodes
    def root
      find(:all, :order => "lft ASC, rgt DESC").first
    end
    
    protected
    #--
    # TODO: refactor this
    # converts the hash returned from a YAML read into a list of linked OpenStructs
    #++
    def hash_to_linked_list(h)
      list = []
      q = FiloStack.new("stack")
      current = nil
      depth = 0
      parent = OpenStruct.new(:obj => h, :name => "root", :value => nil, :parent => nil, :depth => depth)
      q.push parent
      list << parent
      begin
        current = q.pop
        case current.obj
        when OpenStruct
          parent = current
          current.obj.each_key do |key|
            q.push OpenStruct.new(:obj => current.obj[key], :name => key, :value => nil, :parent => parent, :depth => parent.depth+1)
            list << q.current
          end
        when Hash
          parent = current
          current.obj.each_key do |key|
            #-- look ahead even more, if the next child is a string, add it to this value instead
            if current.obj[key].is_a?(String)
              q.push OpenStruct.new(:obj => nil, :name => key, :value => current.obj[key], :parent => parent, :depth => parent.depth+1)
            else
              q.push OpenStruct.new(:obj => current.obj[key], :name => key, :value => nil, :parent => parent, :depth => parent.depth+1)
            end
            list << q.current
          end
        when String
        when nil
          next
        end
      end until q.empty?
      return list.sort{ |a,b| a.depth <=> b.depth }
    end
    
    #--
    # TODO: refactor this
    # converts the array of OpenStructs returned from hash_to_linked_list
    #++
    def linked_list_to_nested_set(list)
      total = list.length
      s = Set.new(list)
      #-- do we still need the by_parents thing?
      by_parents = s.classify{ |os| os.parent }
      #-- instead of doing it by parent, maybe by depth?
      by_depth = s.classify{ |os| os.depth }
      #-- nil as a parent means it is the root, so create it
      root_os = by_parents.delete(nil).find{|x|true}
      root_ci = create(:param_name => root_os.name, :param_value => root_os.value)
      #-- PENDING? make sure the by_parents hash is sorted correctly
      os_ci = {}
      #-- seed the os_ci with the root
      os_ci[root_os] = root_ci
      #-- go to each parent, which is an OS
      #-- by_parents.each_key do |parent_os|
      by_depth.each_key do |depth|
        by_depth[depth].to_a.each do |parent_os|
          #-- first look for a ci for this parent_os
          if os_ci.has_key?(parent_os)
            parent_ci = os_ci[parent_os]
          else
          #-- there wasn't already one, so create a ConfigItem from this OS
            parent_ci = create(:param_name => parent_os.name, :param_value => parent_os.value)
            #-- and add it to to the os_ci map
            os_ci[parent_os] = parent_ci
          end
          #-- parent_ci and parent_os should both be set and valid now, as well as be in the map
          #-- look for IT'S parent so we can add_child to it
          grandparent_os = parent_os.parent
          if os_ci.has_key?(grandparent_os)
          #-- the grandparent -- or parent of this parent -- was already created
          #-- assuming these are being created in depth order, we shouldn't have to create the grandparent here
            os_ci[grandparent_os].add_child(parent_ci)
          end
        end
      end
    end
    
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
    # TODO: do an all_children call, or use db via class method?
    # really it should be the lowest depth ergo most children that we find, since there is 
    # no column for this (should there be?) have to do max of right-left
    #++
    tmp = self.class.find(:all, :conditions => { :param_name => arg.to_s, :parent_id => id })
    return nil if tmp.blank?
    return tmp.max{ |a,b| (a.rgt - a.lft) <=> (b.rgt - b.lft) }
  end
  
  def parent
    return nil if parent_id.nil?
    self.class.find(parent_id)
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
