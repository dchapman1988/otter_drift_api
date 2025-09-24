class ChangeSeedToBigintInGameSessions < ActiveRecord::Migration[8.0]
  def change
    change_column :game_sessions, :seed, :bigint
  end
end
