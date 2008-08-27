unless File.exists? File.expand_path(File.dirname(__FILE__)  + "/../acts_as_nested_set")
  puts "This plugin require the acts_as_nested_set plugin"
  puts "available at git://github.com/rails/acts_as_nested_set.git"
  abort "Please install the required plugins before continuing"
end