class MakeChannelCategoryOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :channels, :category_id, true
  end
end
