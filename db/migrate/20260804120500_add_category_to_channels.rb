class AddCategoryToChannels < ActiveRecord::Migration[8.1]
  def change
    add_reference :channels, :category, foreign_key: true
  end
end
