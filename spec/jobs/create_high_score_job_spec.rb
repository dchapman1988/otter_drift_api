require 'rails_helper'

RSpec.describe CreateHighScoreJob, type: :job do
  let(:game_session) { create(:game_session, final_score: 100) }

  it "creates a high score from a game session" do
    expect {
      described_class.perform_now(game_session.id)
    }.to change(HighScore, :count).by(1)
  end

  it "creates a HighScore with the correct score" do
    described_class.perform_now(game_session.id)
    high_score = HighScore.last
    expect(high_score.score).to eq(game_session.final_score)
  end
end
