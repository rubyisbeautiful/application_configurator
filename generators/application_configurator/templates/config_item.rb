class ConfigItem < ActiveRecord::Base
  # The main storage for the class, allowing the values to be instantiated on class method calls
  @@items = {}
  @@create_on_nil = true
  cattr_accessor :create_on_nil
  validates_presence_of :param_name, :param_value
  
  class <<self
    
    # Return a hash of all items
    def items
      if @@items.blank?
        self.load
      end
      @@items
    end
    
    # TODO: replace with something generic
    def admin(arg)
      real_key = "admin_#{arg.to_s}".to_sym
      self[real_key]
    end
    
    # A convenience method for accessing top-level params by key in a Hash-like way
    # can be chained
    # example: ConfigItem[:foo] -> # will find the recorded value associated with param_name "foo"
    # chaining example: ConfigItem[:foo] -> # returns a hash
    #                   ConfigItem[:foo][:bar]
    # if create_on_nil is true, will create an empty hash key if the key is not found
    def [](arg)
      if arg.blank?
        return nil
      end
      if self.items[arg].blank?
        self.create(:param_name => arg.to_s, :param_value => nil)
      end
      self.items[arg]
    end
  
    # A convenience method for assigning top-level params in a Hash-like way
    # can be chanined
    # returns the value assigned
    def []=(arg, val)
      foo = find_or_create_by_param_name(arg.to_s)
      foo.update_attributes(:param_value => val)
      self.load
      self.items[arg.to_sym]
    end
  
    # pre-Load db rows into the @@items hash
    def load
      @@items = {}
      all.each do |ci|
        @@items[ci.param_name.to_sym] = ci.param_value
      end
    end
    
    # set the specified item to read-only, only partially implemented
    def read_only(item)
      foo = find_by_param_name(item.to_s)
      foo.update_attributes(:read_only => true)
    end
  
    # generate a new application.yml based on the values currently loaded in @@items
    def to_application_yaml
      y = Hash.new
      all(:order => "param_name").each do |ci|
        pieces = ci.param_name.split("_")
        section = pieces.shift
        y[section] = {} if y[section].blank?
        y[section][pieces.join("_")]=ci.param_value
      end
      return y.to_yaml
    end
    
  end
  
  protected
  def after_save
    @@items[param_name.to_sym] = param_value
  end
  
  def before_destroy
    @@items.delete(param_name.to_sym)
  end
  
end
