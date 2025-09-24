require "rails_helper"

RSpec.describe GameSession, type: :model do
  it "has a valid factory" do
    expect(build(:game_session)).to be_valid
  end

  it "generates a UUID for session_id by default" do
    gs = create(:game_session)
    expect(gs.session_id).to be_present
    expect(gs.session_id).to match(/\A[0-9a-f-]{36}\z/i)
  end
end

