require "rails_helper"

RSpec.describe GameSession, type: :model do
  describe "High Scores" do
    it "enqueues the CreateHighScoreJob" do
      expect {
        create(:game_session)
      }.to have_enqueued_job(CreateHighScoreJob)
    end
  end
end

