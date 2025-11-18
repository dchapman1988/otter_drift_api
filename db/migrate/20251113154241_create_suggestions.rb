class CreateSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestions do |t|
      t.text :note
      t.references :player, null: true, foreign_key: true, index: true

      t.timestamps
    end
  end
end
