class AddAchievementTypeToAchievements < ActiveRecord::Migration[8.0]
  def change
    add_column :achievements, :achievement_type, :string
    add_index :achievements, :achievement_type, unique: true
  end
end
