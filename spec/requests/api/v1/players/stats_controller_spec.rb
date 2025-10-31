require 'rails_helper'

RSpec.describe "Api::V1::StatsController", type: :request do
  let(:player) {
    create(:player)
  }

  describe "GET /player/stats" do
    before do
      sign_in player
    end

    it "should return some stats" do
      get api_v1_players_stats_path
      json_response = JSON.parse(response.body)
      expect(json_response["player_stats"]["total_score"]).to be >= 0
      expect(json_response["player_stats"]["games_played"]).to be >= 0
      expect(json_response["player_stats"]["personal_best"]).to be >= 0
    end
  end
end
