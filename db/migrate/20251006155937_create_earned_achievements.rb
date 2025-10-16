class CreateEarnedAchievements < ActiveRecord::Migration[8.0]
  def change
    create_table :earned_achievements do |t|
      t.references :player, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.references :game_session, null: true, foreign_key: true
      t.datetime :earned_at

      t.timestamps
    end

    # Prevent earning the same achievement twice
    add_index :earned_achievements, [ :player_id, :achievement_id ], unique: true
    add_index :earned_achievements, :earned_at
  end
end
