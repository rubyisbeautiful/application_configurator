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
  
  def edit
    config_item = ConfigItem.find(params[:id])
    render :partial => 'edit', :locals => {:config_item => config_item}
  end  
  
  def update
    config_item = ConfigItem.find(params[:id])
    config_item.update_attributes(params[:config_item])
    render :partial => 'show', :locals => {:config_item => config_item}
  end  

end