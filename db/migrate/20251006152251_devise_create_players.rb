# frozen_string_literal: true

class DeviseCreatePlayers < ActiveRecord::Migration[7.0]
  def change
    create_table :players do |t|
      # Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      # Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      # Rememberable
      t.datetime :remember_created_at

      # Trackable (optional but useful for game analytics)
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # Player-specific fields
      t.string :username, null: false
      t.string :display_name
      t.string :avatar_url
      t.integer :total_score, default: 0
      t.integer :games_played, default: 0
      t.datetime :last_played_at

      t.timestamps null: false
    end

    add_index :players, :email,                unique: true
    add_index :players, :reset_password_token, unique: true
    add_index :players, :username,             unique: true
  end
end
