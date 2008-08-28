class ConfigItemsController < ApplicationController
  
  def index
    params[:level] ||= 1
    @config_items = ConfigItem.dig(Integer(params[:level]))
    #-- on index page, default to finding only top level items    
  end
  
end
