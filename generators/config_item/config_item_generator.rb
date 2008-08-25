class ApplicationConfiguratorGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory "app/models"
      m.template("config_item.rb", "app/models/config_item.rb", :collision => :ask)
    end
  end
end
