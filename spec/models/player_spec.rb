require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'factory' do
    it 'creates a valid player' do
      player = build(:player)
      expect(player).to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:game_sessions).dependent(:destroy) }
    it { should have_many(:earned_achievements).dependent(:destroy) }
    it { should have_many(:achievements).through(:earned_achievements) }
    it { should have_one(:player_profile).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:player) }

    describe 'username' do
      it { should validate_presence_of(:username) }
      it { should validate_length_of(:username).is_at_least(3).is_at_most(20) }

      it 'validates uniqueness case-insensitively' do
        create(:player, username: 'TestUser')
        duplicate = build(:player, username: 'testuser')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:username]).to include('has already been taken')
      end

      it 'allows different usernames' do
        create(:player, username: 'user1')
        player2 = build(:player, username: 'user2')
        expect(player2).to be_valid
      end
    end

    describe 'display_name' do
      it { should validate_length_of(:display_name).is_at_most(30) }
      it { should allow_value(nil).for(:display_name) }
      it { should allow_value('').for(:display_name) }
      it { should allow_value('John Doe').for(:display_name) }
    end

    describe 'avatar_url' do
      it { should validate_length_of(:avatar_url).is_at_most(500) }
      it { should allow_value(nil).for(:avatar_url) }
      it { should allow_value('').for(:avatar_url) }
      it { should allow_value('https://example.com/avatar.png').for(:avatar_url) }
      it { should allow_value('http://example.com/avatar.jpg').for(:avatar_url) }
      it { should_not allow_value('not-a-url').for(:avatar_url).with_message('must be a valid URL') }
      it { should_not allow_value('ftp://example.com/file').for(:avatar_url).with_message('must be a valid URL') }
    end

    describe 'email' do
      it 'validates uniqueness case-insensitively' do
        create(:player, email: 'Test@Example.com')
        duplicate = build(:player, email: 'test@example.com')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include('has already been taken')
      end
    end
  end

  describe '#display_name_or_username' do
    it 'returns display_name when present' do
      player = build(:player, username: 'johndoe', display_name: 'John Doe')
      expect(player.display_name_or_username).to eq('John Doe')
    end

    it 'returns username when display_name is nil' do
      player = build(:player, username: 'johndoe', display_name: nil)
      expect(player.display_name_or_username).to eq('johndoe')
    end

    it 'returns username when display_name is empty string' do
      player = build(:player, username: 'johndoe', display_name: '')
      expect(player.display_name_or_username).to eq('johndoe')
    end
  end

  describe '#personal_best' do
    it 'returns the highest final_score from completed game sessions' do
      player = create(:player)
      create(:game_session, player: player, final_score: 100, ended_at: Time.current)
      create(:game_session, player: player, final_score: 250, ended_at: Time.current)
      create(:game_session, player: player, final_score: 175, ended_at: Time.current)

      expect(player.personal_best).to eq(250)
    end

    it 'returns 0 when player has no game sessions' do
      player = create(:player)
      expect(player.personal_best).to eq(0)
    end

    it 'returns 0 when player has no completed game sessions' do
      player = create(:player)
      create(:game_session, player: player, final_score: nil, ended_at: nil)

      expect(player.personal_best).to eq(0)
    end
  end

  describe '#achievement_count' do
    it 'returns the count of earned achievements' do
      player = create(:player)
      create_list(:earned_achievement, 3, player: player)

      expect(player.achievement_count).to eq(3)
    end

    it 'returns 0 when player has no achievements' do
      player = create(:player)
      expect(player.achievement_count).to eq(0)
    end
  end
end
