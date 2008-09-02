namespace :application do
  
  desc "Macro task to configure the application"
  task :configure => [:environment, :bootstrap] do
    root = File.expand_path(File.dirname(__FILE__)+"/../..")
    abort("Need to configure the application.yml first!") unless File.exists?(root + '/config/application.yml')
    require 'rails_generator'
    require File.expand_path(File.dirname(__FILE__)) + '/../generators/application_generator'
    ApplicationGenerator.new.command('create').invoke!
  end
    
  desc "Delete all configuration records from the db"
  task :unconfigure => [:environment] do
    ConfigItem.delete_all
  end
  
  desc "Bootstrap the application configuration by loading from application.yml"
  task :bootstrap => :environment do
    ConfigItem.read_from_yml
  end
  
end