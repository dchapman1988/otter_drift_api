class CreateAchievements < ActiveRecord::Migration[8.0]
  def change
    create_table :achievements do |t|
      t.string :type # for STI
      t.string :name
      t.text :description
      t.string :icon_url
      t.bigint :points
      t.boolean :hidden, default: false # for hidden achievements!

      t.timestamps
    end
  end
end
