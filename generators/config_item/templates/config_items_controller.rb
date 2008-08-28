class ConfigItemsController < ApplicationController
  
  def index
    params[:level] ||= 1
    @config_items = ConfigItem.dig(Integer(params[:level]))
    #-- on index page, default to finding only top level items    
  end
  
  def show
    config_item = ConfigItem.find(params[:id])
  end
  
  def children
    @config_item = ConfigItem.find(params[:id])
    children = @config_item.direct_children
    render :partial => 'children.html.haml', :locals => { :children => children } and return false
  end
  
end