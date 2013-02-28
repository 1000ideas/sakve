class AddItemsCountToTag < ActiveRecord::Migration
  def change
    add_column :tags, :items_count, :integer, null: false, default: 0

    say_with_time "Updating counter cache column..." do 
      Tag.all.each do |tag|
        Tag.update_counters tag.id, items_count: tag.items.count
      end
    end
  end
end
