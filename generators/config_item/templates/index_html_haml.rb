- @config_items.each_key do |level|
  %ul
  - @config_items[level].each do |config_item|
    %li= "#{config_item.param_name} | #{config_item.param_value}"