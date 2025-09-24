class CreateHighScores < ActiveRecord::Migration[8.0]
  def change
    create_table :high_scores do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :player_name
      t.integer :score

      t.timestamps
    end
  end
end
