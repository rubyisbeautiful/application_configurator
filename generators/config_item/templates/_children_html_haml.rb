%li
  = @config_item.param_name
- children.each do |config_item|
  %ul
    - if config_item.param_value.nil?
      %li{:id => "config_item_#{config_item.id}"}
        = link_to_remote config_item.param_name, :url => children_config_item_path(config_item), :update => "config_item_#{config_item.id}", :method => :get
    - else
      %li= "Name: #{config_item.param_name} -- Value: #{config_item.param_value}"