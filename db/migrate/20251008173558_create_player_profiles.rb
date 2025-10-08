class CreatePlayerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :player_profiles do |t|
      t.text :bio
      t.text :favorite_otter_fact
      t.string :title
      t.string :profile_banner_url
      t.string :location
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end

    add_index :player_profiles, :title # for future find all players with X title
    add_index :player_profiles, :location # could seach by location
  end
end
