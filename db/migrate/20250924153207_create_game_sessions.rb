class CreateGameSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :game_sessions do |t|
      t.uuid :session_id
      t.string :player_name
      t.integer :seed
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :final_score
      t.float :game_duration
      t.float :max_speed_reached
      t.integer :obstacles_avoided
      t.integer :lilies_collected

      t.timestamps
    end
  end
end
