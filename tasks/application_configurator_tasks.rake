namespace :application do
      
  desc "Delete all configuration records from the db"
  task :unconfigure => [:environment] do
    ConfigItem.delete_all
  end
  
  desc "Bootstrap the application configuration by loading from application.yml"
  task :bootstrap => :environment do
    ConfigItem.from_hash
  end
  
end