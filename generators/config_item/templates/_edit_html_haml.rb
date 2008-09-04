- remote_form_for :config_item, config_item, :url => config_item_path(config_item), :update => "show_edit_config_item_#{config_item.id}", :method => :put do |f|
  Name:
  = f.text_field 'param_name'
  Value
  = f.text_field :param_value
  = submit_tag 'Update'