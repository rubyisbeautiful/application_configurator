require 'ostruct'

class ConfigItem < ActiveRecord::Base
  validates_presence_of :param_name
  acts_as_nested_set
  
  class <<self
    # Return a hash of all items
    # def items
    #     end
    
    # TODO: replace with something generic
    # def admin(arg)
    #       real_key = "admin_#{arg.to_s}".to_sym
    #       self[real_key]
    #     end
    
    # A convenience method for accessing top-level params by key in a Hash-like way
    # can be chained
    # example: ConfigItem[:foo] -> # will find the recorded value associated with param_name "foo"
    # chaining example: ConfigItem[:foo] -> # returns a hash
    #                   ConfigItem[:foo][:bar]
    # if create_on_nil is true, will create an empty hash key if the key is not found
    def [](arg)
      return nil if arg.blank?
      # really it should be the lowest depth ergo most children that we find, since there is 
      # no column for this (should there be?) have to do max of right-left
      tmp = find(:all, :conditions => { :param_name => arg.to_s })
      return nil if tmp.blank?
      return tmp.max{ |a,b| (a.rgt - a.lft) <=> (b.rgt - b.lft) }
      # result = {}
      # tmp.max{ |a,b| (a.rgt - a.lft) <=> (b.rgt - b.lft) }.all_children.each do |child|
      #         result[child.param_name]=child
      #       end
      # return result      
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
    
    # read the application.yml file and create/update db rows
    def read_from_yml(target = File.expand_path(File.dirname(__FILE__) + '/../../config/application.yml'))
      h = YAML.load_file(target)
      raise StandardError.new("Configuration not loaded!") if h.blank?
      linked_list = hash_to_linked_list(h)
      # return linked_list
      linked_list_to_nested_set(linked_list)
      # return nested_set
    #   save_to_db(nested_set)
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
  
    # generate a new application.yml based on the values currently loaded in @@items
    # def to_application_yaml
    #      y = Hash.new
    #      all(:order => "param_name").each do |ci|
    #        pieces = ci.param_name.split("_")
    #        section = pieces.shift
    #        y[section] = {} if y[section].blank?
    #        y[section][pieces.join("_")]=ci.param_value
    #      end
    #      return y.to_yaml
    #    end
    
    # def create_root(params={}, new_right = 4)
    #      new_root = self.create(params)
    #      new_root.update_attributes(:lft => 1, :rgt => new_right)
    #      return new_root
    #    end
    
    # Protected class methods
    # protected
    
    # def visit(name, value=nil, parent=nil)
    #       ci = ConfigItem.create(:param_name => name, :param_value => value)
    #       unless parent.nil?
    #         parent.add_child(ci)
    #       end
    #       return ci
    #     end
    
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
            # look ahead even more, if the next child is a string, add it to this value instead
            if current.obj[key].is_a?(String)
              q.push OpenStruct.new(:obj => nil, :name => key, :value => current.obj[key], :parent => parent, :depth => parent.depth+1)
            else
              q.push OpenStruct.new(:obj => current.obj[key], :name => key, :value => nil, :parent => parent, :depth => parent.depth+1)
            end
            list << q.current
          end
        when String
          # list << OpenStruct.new(:obj => current.obj, :name => current.obj, :parent => current)
          puts "not doing anything, this String should be added to its parent's 'value'"
        when nil
          next
        end
      end until q.empty?
      return list.sort{ |a,b| a.depth <=> b.depth }
    end
  
    def linked_list_to_nested_set(list)
      total = list.length
      s = Set.new(list)
      by_parents = s.classify{ |os| os.parent }
      # instead of doing it by parent, maybe by depth?
      by_depth = s.classify{ |os| os.depth }
      # nil as a parent means it is the root, so create it
      root_os = by_parents.delete(nil).find{|x|true}
      root_ci = create(:param_name => root_os.name, :param_value => root_os.value)
      # PENDING? make sure the by_parents hash is sorted correctly
      os_ci = {}
      # seed the os_ci with the root
      os_ci[root_os] = root_ci
      # go to each parent, which is an OS
      # by_parents.each_key do |parent_os|
      by_depth.each_key do |depth|
        by_depth[depth].to_a.each do |parent_os|
          # first look for a ci for this parent_os
          if os_ci.has_key?(parent_os)
            parent_ci = os_ci[parent_os]
          else
          # there wasn't already one, so create a ConfigItem from this OS
            parent_ci = create(:param_name => parent_os.name, :param_value => parent_os.value)
            # and add it to to the os_ci map
            os_ci[parent_os] = parent_ci
          end
          # parent_ci and parent_os should both be set and valid now, as well as be in the map
          # look for IT'S parent so we can add_child to it
          grandparent_os = parent_os.parent
          if os_ci.has_key?(grandparent_os)
          # the grandparent -- or parent of this parent -- was already created
          # assuming these are being created in depth order, we shouldn't have to create the grandparent here
            os_ci[grandparent_os].add_child(parent_ci)
          end
          # then loop through the children -- it's a set -- and do those until the end of the children array
          # by_parents[parent_os].each do |child_os|
          #   # create a ci for this child
          #   child_ci = create(:param_name => child_os.name)
          #   # add the new child to the lookup
          #   os_ci[child_os] = child_ci
          #   # add the new ci to the parent ci
          #   parent_ci.add_child(child_ci)
          # end
        end
      end
    end
    
  end
  
  # can be chained
  def [](arg)
    return nil if arg.blank?
    # do an all_children call, or use db via class method?
    # really it should be the lowest depth ergo most children that we find, since there is 
    # no column for this (should there be?) have to do max of right-left
    tmp = self.class.find(:all, :conditions => { :param_name => arg.to_s, :parent_id => id })
    return nil if tmp.blank?
    return tmp.max{ |a,b| (a.rgt - a.lft) <=> (b.rgt - b.lft) }
  end
  
  def parent
    self.class.find(parent_id)
  end
  
  
  # protected
  # def after_save
  #     @@items[param_name.to_sym] = param_value
  #   end
  #   
  #   def before_destroy
  #     @@items.delete(param_name.to_sym)
  #   end
  
end
