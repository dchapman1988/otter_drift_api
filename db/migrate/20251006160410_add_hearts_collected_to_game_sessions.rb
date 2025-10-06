class AddHeartsCollectedToGameSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :game_sessions, :hearts_collected, :integer
  end
end
