class CreateLogMessages < ActiveRecord::Migration
  def self.up
    create_table :log_messages do |t|
      t.integer :server,                :null => false, :default => 0
      t.integer :pid,                   :null => false, :default => 0
      t.string :worker,  :limit =>  20, :null => false, :default => ''
      t.string :key,     :limit =>  20, :null => false, :default => ''
      t.string :status,  :limit =>  10, :null => false, :default => ''
      t.string :message, :limit => 255, :null => false, :default => ''

      t.timestamps
    end
  end

  def self.down
    drop_table :log_messages
  end
end
