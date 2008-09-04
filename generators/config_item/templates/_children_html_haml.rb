%li
  = @config_item.param_name
- children.each do |config_item|
  %ul
    - if config_item.param_value.blank?
      %li{:id => "config_item_#{config_item.id}"}
        = link_to_remote config_item.param_name, :url => children_config_item_path(config_item), :update => "config_item_#{config_item.id}", :method => :get
    - else
      %li{:id => "show_edit_config_item_#{config_item.id}"}
        = render :partial => 'show.html.haml', :locals => { :config_item => config_item }