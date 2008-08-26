class CreateConfigItems < ActiveRecord::Migration
  def self.up
    create_table :config_items do |t|
      t.column :param_name,   :string, :nil => false
      t.column :param_value,  :string
      t.column :parent_id,    :integer
      t.column :lft,          :integer
      t.column :rgt,          :integer
    end
  end

  def self.down
    drop_table :config_items
  end
end
