class AddHandleToChannels < ActiveRecord::Migration[8.1]
  def change
    add_column :channels, :handle, :string, null: true
    add_index :channels, :handle, unique: true
  end
end
