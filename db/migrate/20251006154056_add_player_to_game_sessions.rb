class AddPlayerToGameSessions < ActiveRecord::Migration[8.0]
  def change
    add_reference :game_sessions, :player, foreign_key: true, null: true

    # Add index for querying player's game history
    add_index :game_sessions, [ :player_id, :final_score ], order: { final_score: :desc }
    add_index :game_sessions, [ :player_id, :created_at ]
  end
end
