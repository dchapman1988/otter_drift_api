require 'rails_helper'

RSpec.describe PlayerProfile, type: :model do
  let(:player_profile) { create(:player_profile) } 

  it "has a banner url" do
    expect(player_profile.profile_banner_url).to_not eq(nil)
  end

  it "has a player" do
    expect(player_profile.player).to_not eq(nil)
  end
end
