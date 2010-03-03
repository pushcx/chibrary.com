class CreateFlags < ActiveRecord::Migration
  def self.up
    create_table :flags do |t|
      t.string  :slug,        :limit => 20, :null => false, :default => ''
      t.integer :year,                      :null => false, :default => 0
      t.integer :month,                     :null => false, :default => 0
      t.string  :call_number, :limit =>  8, :null => false, :default => ''

      t.timestamps
    end
  end

  def self.down
    drop_table :flags
  end
end
