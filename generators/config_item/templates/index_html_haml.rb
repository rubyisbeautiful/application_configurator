Config Items
%br/
%ul
  - @config_items.each do |config_item|
    - if config_item.param_value.nil?
      %li{:id => "config_item_#{config_item.id}"}
        = link_to_remote config_item.param_name, :url => children_config_item_path(config_item), :update => "config_item_#{config_item.id}", :method => :get
    - else
      = render :partial => 'show.html.haml', :locals => { :config_item => config_item }