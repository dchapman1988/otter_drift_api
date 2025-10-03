require 'rails_helper'

RSpec.describe "Api::V1::GameSessions", type: :request do
  before do
    post api_v1_auth_login_path(
      {
        "client_id" => "game_client",
        "api_key" => Rails.application.credentials.test_client
      }
    )
  end

  describe "POST /api/v1/game_sessions" do
    let(:valid_game_session_params) {
      {
        game_session: {
          "session_id" => SecureRandom.uuid,
          "player_name" => Faker::Name.masculine_name,
          "seed" => 12,
          "started_at" => 5.minutes.ago.to_datetime.to_s,
          "ended_at" => Time.now.to_s,
          "final_score" => rand(0..100),
          "max_speed_reached" => 120.0,
          "obstacles_avoided" => rand(0..30),
          "lilies_collected" => rand(0..30)
        }
      }
    }

    it "saves the game session" do
      expect {
        post api_v1_game_sessions_path(valid_game_session_params)
      }.to change { GameSession.count }.by(1)
    end
  end
end
