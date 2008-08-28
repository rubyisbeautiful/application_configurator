class ConfigItemGenerator < Rails::Generator::NamedBase
  
  def manifest
    record do |m|
      
      # directories
      m.directory "app/models"
      m.directory "db/migrate"
      m.directory "app/controllers"
      m.directory "app/views/config_items"
      
      # models
      m.template("config_item.rb", "app/models/config_item.rb", :collision => :ask)
      
      # controllers
      m.template("config_items_controller.rb", "app/controllers/config_items_controller.rb", :collision => :ask)
      
      # views
      m.template("index_html_haml.rb", "app/views/config_items/index.html.haml", :collision => :ask)
      m.template("_show_html_haml.rb", "app/views/config_items/_show.html.haml", :collision => :ask)
      m.template("_children_html_haml.rb", "app/views/config_items/_children.html.haml", :collision => :ask)
      
      # migration
      if Dir.glob("db/migrate/*_create_config_items.rb").empty?
        stamp = Time.now.to_formatted_s(:number)
        m.template("migration.rb", "db/migrate/#{stamp}_create_config_items.rb", :collision => :ask)
      else
        puts "\t\tMigration _create_config_items already exists"
      end          
    end
  end
  
  def banner
    "Usage: #{$0} config_item ConfigItem"
  end
  
end
