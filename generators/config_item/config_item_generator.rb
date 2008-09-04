class ConfigItemGenerator < Rails::Generator::NamedBase
  
  def initialize(runtime_args, runtime_options = {})
    super
    puts "Ran with options:"
    puts options
  end
  
  def manifest
    record do |m|
      
      begin
        gem 'rspec'
        gem_rspec = true
      rescue
        gem_rspec = false
      end
      
      @rspec = gem_rspec && !options[:norspec]
      
      #-- only in cool newer versions of gem 
      #-- Gem.available?("rspec") && !options[:norspec]
        
      # directories
      m.directory "app/models"
      m.directory "db/migrate"
      m.directory "app/controllers"
      m.directory "app/views/config_items"
      if @rspec
        m.directory "spec/models"
        m.directory "spec/controllers"
        m.directory "spec/fixtures"
      end
      
      # models
      m.template("config_item.rb", "app/models/config_item.rb", :collision => options[:collision])
      
      # controllers
      m.template("config_items_controller.rb", "app/controllers/config_items_controller.rb", :collision => options[:collision])
      
      # views
      m.template("index_html_haml.rb", "app/views/config_items/index.html.haml", :collision => options[:collision])
      m.template("_show_html_haml.rb", "app/views/config_items/_show.html.haml", :collision => options[:collision])
      m.template("_children_html_haml.rb", "app/views/config_items/_children.html.haml", :collision => options[:collision])
      m.template("_edit_html_haml.rb", "app/views/config_items/_edit.html.haml", :collision => options[:collision])
      
      # specs
      if @rspec
        m.template("config_item_model_spec.rb", "spec/models/config_item_spec.rb", :collision => options[:collision])
        m.template("config_items_controller_spec.rb", "spec/controllers/config_items_controller_spec.rb", :collision => options[:collision])
        m.template("config_items_yml.rb", "spec/fixtures/config_items.yml", :collision => options[:collision])
      end
      
      # routing
      # TODO: add routes
      
      # migration
      if Dir.glob("db/migrate/*config_items.rb").empty?
        stamp = Time.now.to_formatted_s(:number)
        m.template("migration.rb", "db/migrate/#{stamp}_create_config_items.rb", :collision => options[:collision])
      else
        puts "\t\tMigration _create_config_items already exists"
      end          
    end
  end
  
  def banner
    "Usage: #{$0} config_item ConfigItem"
  end
  
end
