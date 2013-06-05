ActiveRecord::Schema.define do
  create_table(:books, :force => true) do |t|
    t.string  :title
    t.string  :author
    t.integer :year
    t.string  :blurb_file
    t.boolean :delta, :default => true, :null => false
    t.timestamps
  end
end
