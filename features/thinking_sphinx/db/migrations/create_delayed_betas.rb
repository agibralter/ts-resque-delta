ActiveRecord::Base.connection.create_table :delayed_beta, :force => true do |t|
  t.column  :name, :string,  :null => false
  t.column :delta, :boolean, :null => false, :default => false
end
