class RemovePlayerNameAndScoreFromHighScores < ActiveRecord::Migration[8.0]
  def change
    remove_column :high_scores, :player_name, :string
    remove_column :high_scores, :score, :integer
  end
end
