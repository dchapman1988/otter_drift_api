require 'rails_helper'

RSpec.describe GameSession, type: :model do
  describe 'associations' do
    it { should belong_to(:player).optional }
    it { should have_many(:high_scores).dependent(:destroy) }
    it { should have_many(:earned_achievements).dependent(:destroy) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:session_id) }
    
    subject { build(:game_session) }
    it { should validate_uniqueness_of(:session_id) }
    
    it { should validate_numericality_of(:final_score).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:lilies_collected).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:obstacles_avoided).is_greater_than_or_equal_to(0).allow_nil }
  end
  
  describe 'scopes' do
    let(:player) { create(:player) }
    let!(:completed_session) { create(:game_session, :completed, player: player) }
    let!(:incomplete_session) { create(:game_session, player: player, ended_at: nil, final_score: nil) }
    let!(:guest_session) { create(:game_session, :completed, player: nil) }
    
    describe '.completed' do
      it 'returns only completed sessions' do
        expect(GameSession.completed).to include(completed_session, guest_session)
        expect(GameSession.completed).not_to include(incomplete_session)
      end
    end
    
    describe '.for_player' do
      it 'returns sessions for specific player' do
        expect(GameSession.for_player(player)).to include(completed_session, incomplete_session)
        expect(GameSession.for_player(player)).not_to include(guest_session)
      end
    end
    
    describe '.guest_sessions' do
      it 'returns only guest sessions' do
        expect(GameSession.guest_sessions).to include(guest_session)
        expect(GameSession.guest_sessions).not_to include(completed_session)
      end
    end
  end
  
  describe '#guest_session?' do
    it 'returns true when player_id is nil' do
      session = build(:game_session, player: nil)
      expect(session.guest_session?).to be true
    end
    
    it 'returns false when player is present' do
      session = build(:game_session, player: create(:player))
      expect(session.guest_session?).to be false
    end
  end
  
  describe '#completed?' do
    it 'returns true when both ended_at and final_score are present' do
      session = build(:game_session, ended_at: Time.current, final_score: 1000)
      expect(session.completed?).to be true
    end
    
    it 'returns false when ended_at is missing' do
      session = build(:game_session, ended_at: nil, final_score: 1000)
      expect(session.completed?).to be false
    end
    
    it 'returns false when final_score is missing' do
      session = build(:game_session, ended_at: Time.current, final_score: nil)
      expect(session.completed?).to be false
    end
  end
  
  describe 'callbacks' do
    describe 'after_commit' do
      it 'enqueues CreateHighScoreJob on create for completed session' do
        session = build(:game_session, :completed)
        
        expect {
          session.save!
        }.to have_enqueued_job(CreateHighScoreJob)
      end
      
      it 'enqueues UpdatePlayerStatsJob for player session' do
        player = create(:player)
        session = build(:game_session, :completed, player: player)
        
        expect {
          session.save!
        }.to have_enqueued_job(UpdatePlayerStatsJob).with { |player_id, session_id|
          expect(player_id).to eq(player.id)
          expect(session_id).to be_present
        }
      end
      
      it 'enqueues CheckAchievementsJob for player session' do
        player = create(:player)
        session = build(:game_session, :completed, player: player)
        
        expect {
          session.save!
        }.to have_enqueued_job(CheckAchievementsJob).with { |player_id, session_id|
          expect(player_id).to eq(player.id)
          expect(session_id).to be_present
        }
      end
      
      context 'guest sessions' do
        it 'enqueues CreateHighScoreJob for guest session' do
          session = build(:game_session, :completed, player: nil)
          
          expect {
            session.save!
          }.to have_enqueued_job(CreateHighScoreJob)
        end
        
        it 'does not enqueue UpdatePlayerStatsJob for guest session' do
          session = build(:game_session, :completed, player: nil)
          
          expect {
            session.save!
          }.not_to have_enqueued_job(UpdatePlayerStatsJob)
        end
        
        it 'does not enqueue CheckAchievementsJob for guest session' do
          session = build(:game_session, :completed, player: nil)
          
          expect {
            session.save!
          }.not_to have_enqueued_job(CheckAchievementsJob)
        end
      end
      
      context 'incomplete sessions' do
        it 'does not enqueue UpdatePlayerStatsJob for incomplete session' do
          player = create(:player)
          session = build(:game_session, player: player, ended_at: nil, final_score: nil)
          
          expect {
            session.save!
          }.not_to have_enqueued_job(UpdatePlayerStatsJob)
        end
        
        it 'does not enqueue CheckAchievementsJob for incomplete session' do
          player = create(:player)
          session = build(:game_session, player: player, ended_at: nil, final_score: nil)
          
          expect {
            session.save!
          }.not_to have_enqueued_job(CheckAchievementsJob)
        end
      end
    end
  end
end
