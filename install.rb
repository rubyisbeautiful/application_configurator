unless File.exists? File.expand_path(File.dirname(__FILE__)  + "/../acts_as_nested_set")
  puts "This plugin requires the betternestedset plugin"
  puts "available at svn://rubyforge.org/var/svn/betternestedset/tags/stable/betternestedset"
  abort "Please install the required plugins before continuing"
end