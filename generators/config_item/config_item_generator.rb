class ConfigItemGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory "app/models"
      m.directory "db/migrate"
      m.template("config_item.rb", "app/models/config_item.rb", :collision => :force) #ask
      if Dir.glob("db/migrate/*_create_config_items.rb").empty?
        stamp = Time.now.to_formatted_s(:number)
        m.template("migration.rb", "db/migrate/#{stamp}_create_config_items.rb", :collision => :ask)
      else
        puts "Migration _create_config_items already exists"
      end
    end
  end
end
