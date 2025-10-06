require 'rails_helper'

RSpec.describe "Api::V1::GameSessions", type: :request do
  let(:player) { create(:player) }
  let(:valid_attributes) do
    {
      session_id: SecureRandom.uuid,
      player_name: 'TestOtter',
      seed: 12345,
      started_at: 1.minute.ago,
      ended_at: Time.current,
      final_score: 1500,
      game_duration: 60,
      max_speed_reached: 25.5,
      obstacles_avoided: 10,
      lilies_collected: 15
    }
  end
  
  let(:invalid_attributes) do
    {
      session_id: nil,
      final_score: -100
    }
  end
  
  describe 'POST /api/v1/game_sessions' do
    context 'when player is authenticated' do
      before do
        sign_in player
      end
      
      context 'with valid parameters' do
        it 'creates a new GameSession' do
          expect {
            post api_v1_game_sessions_path, params: { game_session: valid_attributes }
          }.to change(GameSession, :count).by(1)
        end
        
        it 'links the session to the current player' do
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
          expect(GameSession.last.player).to eq(player)
        end
        
        it 'returns a created status' do
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
          expect(response).to have_http_status(:created)
        end
        
        it 'returns the game session data' do
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
          json_response = JSON.parse(response.body)
          
          expect(json_response['game_session']['session_id']).to eq(valid_attributes[:session_id])
          expect(json_response['game_session']['final_score']).to eq(valid_attributes[:final_score])
        end
        
        it 'includes player stats in response for completed session' do
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
          json_response = JSON.parse(response.body)
          
          expect(json_response).to have_key('player_stats')
          expect(json_response['player_stats']).to have_key('total_score')
          expect(json_response['player_stats']).to have_key('games_played')
          expect(json_response['player_stats']).to have_key('personal_best')
        end
        
        it 'enqueues background jobs' do
          expect {
            post api_v1_game_sessions_path, params: { game_session: valid_attributes }
          }.to have_enqueued_job(UpdatePlayerStatsJob)
           .and have_enqueued_job(CheckAchievementsJob)
           .and have_enqueued_job(CreateHighScoreJob)
        end
      end
      
      context 'with invalid parameters' do
        it 'does not create a new GameSession' do
          expect {
            post api_v1_game_sessions_path, params: { game_session: invalid_attributes }
          }.not_to change(GameSession, :count)
        end
        
        it 'returns unprocessable entity status' do
          post api_v1_game_sessions_path, params: { game_session: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
        
        it 'returns error messages' do
          post api_v1_game_sessions_path, params: { game_session: invalid_attributes }
          json_response = JSON.parse(response.body)
          
          expect(json_response).to have_key('errors')
          expect(json_response['errors']).to be_an(Array)
        end
      end
      
      context 'when updating existing session' do
        let!(:existing_session) do
          create(:game_session, 
                 session_id: valid_attributes[:session_id],
                 player: player,
                 ended_at: nil,
                 final_score: nil)
        end
        
        it 'updates the existing session instead of creating new one' do
          expect {
            post api_v1_game_sessions_path, params: { game_session: valid_attributes }
          }.not_to change(GameSession, :count)
          
          existing_session.reload
          expect(existing_session.final_score).to eq(valid_attributes[:final_score])
          expect(existing_session.ended_at).to be_present
        end
      end
    end
    
    context 'when player is not authenticated (guest mode)' do
      it 'creates a guest session' do
        expect {
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
        }.to change(GameSession, :count).by(1)
        
        expect(GameSession.last.player).to be_nil
        expect(GameSession.last.guest_session?).to be true
      end
      
      it 'does not enqueue UpdatePlayerStatsJob' do
        expect {
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
        }.not_to have_enqueued_job(UpdatePlayerStatsJob)
      end
      
      it 'does not enqueue CheckAchievementsJob' do
        expect {
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
        }.not_to have_enqueued_job(CheckAchievementsJob)
      end
      
      it 'still enqueues CreateHighScoreJob' do
        expect {
          post api_v1_game_sessions_path, params: { game_session: valid_attributes }
        }.to have_enqueued_job(CreateHighScoreJob)
      end
      
      it 'does not include player_stats in response' do
        post api_v1_game_sessions_path, params: { game_session: valid_attributes }
        json_response = JSON.parse(response.body)
        
        expect(json_response).not_to have_key('player_stats')
      end
    end
  end
  
  describe 'GET /api/v1/game_sessions' do
    context 'when player is authenticated' do
      before do
        sign_in player
        create_list(:game_session, 3, :completed, player: player)
        create_list(:game_session, 2, :completed, player: create(:player))
      end
      
      it 'returns only the current player\'s sessions' do
        get api_v1_game_sessions_path
        json_response = JSON.parse(response.body)
        
        expect(json_response.length).to eq(3)
      end
      
      it 'returns sessions in descending order' do
        get api_v1_game_sessions_path
        json_response = JSON.parse(response.body)
        
        timestamps = json_response.map { |s| Time.parse(s['created_at']) }
        expect(timestamps).to eq(timestamps.sort.reverse)
      end
      
      it 'limits results to 50 sessions' do
        create_list(:game_session, 60, :completed, player: player)
        
        get api_v1_game_sessions_path
        json_response = JSON.parse(response.body)
        
        expect(json_response.length).to eq(50)
      end
    end
    
    context 'when not authenticated' do
      it 'returns unauthorized status' do
        get api_v1_game_sessions_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
