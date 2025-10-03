class AddScoreToHighScores < ActiveRecord::Migration[8.0]
  def change
    add_column :high_scores, :score, :bigint
  end
end
