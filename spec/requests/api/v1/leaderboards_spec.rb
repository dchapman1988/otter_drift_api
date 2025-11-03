require 'swagger_helper'

RSpec.describe 'api/v1/leaderboard', type: :request do
  path '/api/v1/leaderboard' do
    get('Get Leaderboard') do
      tags 'Leaderboards'
      description 'Retrieves the global leaderboard with top scores, ranked by score (highest first)'
      produces 'application/json'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Number of entries to return (default: 100, max: 500)'

      response(200, 'successful') do
        let!(:player1) { create(:player, username: 'top_player', display_name: 'Top Player') }
        let!(:player2) { create(:player, username: 'second_player', display_name: nil) }
        let!(:game_session1) do
          create(:game_session,
                 player: player1,
                 player_name: 'Top Player',
                 final_score: 10000,
                 ended_at: Time.current)
        end
        let!(:game_session2) do
          create(:game_session,
                 player: player2,
                 player_name: 'second_player',
                 final_score: 8000,
                 ended_at: Time.current)
        end
        let!(:game_session3) do
          create(:game_session,
                 player: nil,
                 player_name: 'Guest123',
                 final_score: 5000,
                 ended_at: Time.current)
        end
        let!(:high_score1) { create(:high_score, game_session: game_session1, score: 10000) }
        let!(:high_score2) { create(:high_score, game_session: game_session2, score: 8000) }
        let!(:high_score3) { create(:high_score, game_session: game_session3, score: 5000) }

        schema type: :object,
          properties: {
            leaderboard: {
              type: :array,
              description: 'Ranked list of high scores',
              items: {
                type: :object,
                properties: {
                  rank: { type: :integer, description: 'Position in leaderboard (1-based)' },
                  score: { type: :integer, description: 'Final score achieved' },
                  player_name: { type: :string, description: 'Display name of the player' },
                  achieved_at: { type: :string, format: 'date-time', description: 'When the score was achieved' },
                  is_guest: { type: :boolean, description: 'Whether this was a guest session' },
                  player: {
                    type: :object,
                    description: 'Player details (only present for authenticated players)',
                    properties: {
                      username: { type: :string, description: 'Player username' },
                      avatar_url: { type: :string, nullable: true, description: 'Player avatar URL' }
                    }
                  }
                },
                required: [ 'rank', 'score', 'player_name', 'achieved_at', 'is_guest' ]
              }
            },
            total_entries: { type: :integer, description: 'Number of entries returned' },
            limit: { type: :integer, description: 'Applied limit for this request' }
          },
          required: [ 'leaderboard', 'total_entries', 'limit' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['leaderboard'].length).to eq(3)
          expect(data['total_entries']).to eq(3)
          expect(data['limit']).to eq(100)

          # Verify ranking order
          expect(data['leaderboard'][0]['rank']).to eq(1)
          expect(data['leaderboard'][0]['score']).to eq(10000)
          expect(data['leaderboard'][0]['player_name']).to eq('Top Player')
          expect(data['leaderboard'][0]['is_guest']).to be false
          expect(data['leaderboard'][0]['player']['username']).to eq('top_player')

          expect(data['leaderboard'][1]['rank']).to eq(2)
          expect(data['leaderboard'][1]['score']).to eq(8000)
          expect(data['leaderboard'][1]['player_name']).to eq('second_player')
          expect(data['leaderboard'][1]['is_guest']).to be false

          expect(data['leaderboard'][2]['rank']).to eq(3)
          expect(data['leaderboard'][2]['score']).to eq(5000)
          expect(data['leaderboard'][2]['player_name']).to eq('Guest123')
          expect(data['leaderboard'][2]['is_guest']).to be true
          expect(data['leaderboard'][2]['player']).to be_nil
        end
      end

      response(200, 'successful - with limit parameter') do
        let(:limit) { 2 }
        let!(:player1) { create(:player, username: 'player1') }
        let!(:game_session1) { create(:game_session, player: player1, final_score: 10000, ended_at: Time.current) }
        let!(:game_session2) { create(:game_session, player: player1, final_score: 8000, ended_at: Time.current) }
        let!(:game_session3) { create(:game_session, player: player1, final_score: 6000, ended_at: Time.current) }
        let!(:high_score1) { create(:high_score, game_session: game_session1, score: 10000) }
        let!(:high_score2) { create(:high_score, game_session: game_session2, score: 8000) }
        let!(:high_score3) { create(:high_score, game_session: game_session3, score: 6000) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['leaderboard'].length).to eq(2)
          expect(data['total_entries']).to eq(2)
          expect(data['limit']).to eq(2)
          expect(data['leaderboard'][0]['score']).to eq(10000)
          expect(data['leaderboard'][1]['score']).to eq(8000)
        end
      end

      response(200, 'successful - empty leaderboard') do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['leaderboard']).to eq([])
          expect(data['total_entries']).to eq(0)
          expect(data['limit']).to eq(100)
        end
      end
    end
  end

  # Additional test cases not in Swagger docs
  describe 'GET /api/v1/leaderboard' do
    context 'with limit parameter' do
      it 'respects the limit parameter' do
        player = create(:player)
        5.times do |i|
          game_session = create(:game_session, player: player, final_score: (5 - i) * 1000, ended_at: Time.current)
          create(:high_score, game_session: game_session, score: (5 - i) * 1000)
        end

        get '/api/v1/leaderboard', params: { limit: 3 }

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['leaderboard'].length).to eq(3)
        expect(data['limit']).to eq(3)
      end

      it 'caps limit at MAX_LIMIT (500)' do
        get '/api/v1/leaderboard', params: { limit: 1000 }

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['limit']).to eq(500)
      end

      it 'uses default limit when limit is 0' do
        get '/api/v1/leaderboard', params: { limit: 0 }

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['limit']).to eq(100)
      end

      it 'uses default limit when limit is negative' do
        get '/api/v1/leaderboard', params: { limit: -10 }

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['limit']).to eq(100)
      end

      it 'uses default limit when limit is blank' do
        get '/api/v1/leaderboard', params: { limit: '' }

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['limit']).to eq(100)
      end
    end

    context 'ranking order' do
      it 'ranks by score descending' do
        player = create(:player)
        game_session1 = create(:game_session, player: player, final_score: 5000, ended_at: Time.current)
        game_session2 = create(:game_session, player: player, final_score: 10000, ended_at: Time.current)
        game_session3 = create(:game_session, player: player, final_score: 7500, ended_at: Time.current)

        create(:high_score, game_session: game_session1, score: 5000, created_at: 3.days.ago)
        create(:high_score, game_session: game_session2, score: 10000, created_at: 2.days.ago)
        create(:high_score, game_session: game_session3, score: 7500, created_at: 1.day.ago)

        get '/api/v1/leaderboard'

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        scores = data['leaderboard'].map { |entry| entry['score'] }
        expect(scores).to eq([ 10000, 7500, 5000 ])
        ranks = data['leaderboard'].map { |entry| entry['rank'] }
        expect(ranks).to eq([ 1, 2, 3 ])
      end

      it 'breaks ties by created_at (earliest first)' do
        player = create(:player)
        game_session1 = create(:game_session, player: player, final_score: 10000, ended_at: Time.current)
        game_session2 = create(:game_session, player: player, final_score: 10000, ended_at: Time.current)

        high_score1 = create(:high_score, game_session: game_session1, score: 10000)
        high_score1.update_column(:created_at, 2.days.ago)

        high_score2 = create(:high_score, game_session: game_session2, score: 10000)
        high_score2.update_column(:created_at, 1.day.ago)

        get '/api/v1/leaderboard'

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['leaderboard'][0]['achieved_at']).to eq(high_score1.created_at.as_json)
        expect(data['leaderboard'][1]['achieved_at']).to eq(high_score2.created_at.as_json)
      end
    end

    context 'player information' do
      it 'includes player details for authenticated players' do
        player = create(:player, username: 'testplayer', display_name: 'Test Player', avatar_url: 'https://example.com/avatar.png')
        game_session = create(:game_session, player: player, final_score: 10000, ended_at: Time.current)
        create(:high_score, game_session: game_session, score: 10000)

        get '/api/v1/leaderboard'

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        entry = data['leaderboard'][0]

        expect(entry['player_name']).to eq('Test Player')
        expect(entry['is_guest']).to be false
        expect(entry['player']['username']).to eq('testplayer')
        expect(entry['player']['avatar_url']).to eq('https://example.com/avatar.png')
      end

      it 'uses username when display_name is nil' do
        player = create(:player, username: 'testplayer', display_name: nil)
        game_session = create(:game_session, player: player, final_score: 10000, ended_at: Time.current)
        create(:high_score, game_session: game_session, score: 10000)

        get '/api/v1/leaderboard'

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['leaderboard'][0]['player_name']).to eq('testplayer')
      end

      it 'uses game_session player_name for guest sessions' do
        game_session = create(:game_session, player: nil, player_name: 'GuestPlayer123', final_score: 10000, ended_at: Time.current)
        create(:high_score, game_session: game_session, score: 10000)

        get '/api/v1/leaderboard'

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        entry = data['leaderboard'][0]

        expect(entry['player_name']).to eq('GuestPlayer123')
        expect(entry['is_guest']).to be true
        expect(entry['player']).to be_nil
      end

      it 'uses "Guest Player" when guest has no player_name' do
        game_session = create(:game_session, player: nil, player_name: nil, final_score: 10000, ended_at: Time.current)
        create(:high_score, game_session: game_session, score: 10000)

        get '/api/v1/leaderboard'

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['leaderboard'][0]['player_name']).to eq('Guest Player')
      end
    end

    context 'mixed player types' do
      it 'includes both authenticated and guest players' do
        player = create(:player, username: 'auth_player', display_name: 'Auth Player')
        auth_session = create(:game_session, player: player, final_score: 10000, ended_at: Time.current)
        guest_session = create(:game_session, player: nil, player_name: 'Guest', final_score: 5000, ended_at: Time.current)

        create(:high_score, game_session: auth_session, score: 10000)
        create(:high_score, game_session: guest_session, score: 5000)

        get '/api/v1/leaderboard'

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)

        expect(data['leaderboard'].length).to eq(2)
        expect(data['leaderboard'][0]['player_name']).to eq('Auth Player')
        expect(data['leaderboard'][0]['is_guest']).to be false
        expect(data['leaderboard'][0]['player']).to be_present

        expect(data['leaderboard'][1]['player_name']).to eq('Guest')
        expect(data['leaderboard'][1]['is_guest']).to be true
        expect(data['leaderboard'][1]['player']).to be_nil
      end
    end
  end
end
