= "#{config_item.param_name}: #{config_item.param_value}"
= link_to_remote 'change', :url => edit_config_item_path(config_item), :update => "show_edit_config_item_#{config_item.id}", :method => :get