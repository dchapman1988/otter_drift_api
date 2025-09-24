require 'rails_helper'

RSpec.describe HighScore, type: :model do

  it 'delegates player name to the game session' do
    hs = create(:high_score)
    hs.reload
    expect(hs.player_name).to eq(hs.game_session.player_name)
  end

  it 'delegates score to the game session' do
    hs = create(:high_score)
    hs.reload
    expect(hs.score).to eq(hs.game_session.final_score)
  end
end
