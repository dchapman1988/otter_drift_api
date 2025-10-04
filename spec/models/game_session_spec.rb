require "rails_helper"

RSpec.describe GameSession, type: :model do
  describe "High Scores" do
    it "creates high score" do
      expect {
        create(:game_session)
      }.to change { HighScore.count }.by(1)
    end

    it "creates only unique high scores" do
      session_id = SecureRandom.uuid
      expect {
        game_session = create(:game_session, final_score: 999, session_id: session_id)
        # This is testing that the after_commit callback is only creating unique high scores
        game_session.update(player_name: Faker::Name.first_name, final_score: 999)
      }.to change { HighScore.count }.by(1)
      expect(HighScore.where(score: 999).size).to eq(1)
    end
  end
end

