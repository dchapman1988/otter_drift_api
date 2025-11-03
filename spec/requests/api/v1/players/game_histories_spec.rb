require 'swagger_helper'

RSpec.describe 'api/v1/players/:username/game-history', type: :request do
  let(:player) { create(:player, username: 'testplayer') }

  path '/api/v1/players/{username}/game-history' do
    parameter name: :username, in: :path, type: :string, description: 'Player username'
    parameter name: :limit, in: :query, type: :integer, required: false, description: 'Number of games to return (default: 20, max: 100)'
    parameter name: :offset, in: :query, type: :integer, required: false, description: 'Offset for pagination (default: 0)'

    get('List Player Game History') do
      tags 'Player Game History'
      description 'Retrieves game history for a player, including all completed game sessions with stats, high scores, and achievements earned'
      produces 'application/json'

      response(200, 'successful') do
        let(:username) { player.username }
        let!(:game_session1) do
          create(:game_session, :completed,
                 player: player,
                 session_id: 'session_1',
                 final_score: 1000,
                 seed: 12345,
                 started_at: 3.days.ago,
                 ended_at: 3.days.ago + 5.minutes,
                 lilies_collected: 10,
                 obstacles_avoided: 5,
                 hearts_collected: 2,
                 max_speed_reached: 50.5)
        end
        let!(:game_session2) do
          create(:game_session, :completed,
                 player: player,
                 session_id: 'session_2',
                 final_score: 2000,
                 seed: 67890,
                 started_at: 1.day.ago,
                 ended_at: 1.day.ago + 10.minutes,
                 lilies_collected: 20,
                 obstacles_avoided: 10,
                 hearts_collected: 4,
                 max_speed_reached: 75.3)
        end
        let!(:high_score1) do
          create(:high_score, game_session: game_session1)
        end
        let!(:high_score2) do
          create(:high_score, game_session: game_session2)
        end
        let!(:achievement) { create(:achievement) }
        let!(:earned_achievement) do
          create(:earned_achievement,
                 player: player,
                 achievement: achievement,
                 game_session: game_session2)
        end

        schema type: :object,
          properties: {
            player: {
              type: :object,
              properties: {
                username: { type: :string, description: 'Player username' },
                total_games: { type: :integer, description: 'Total number of completed games' }
              },
              required: [ 'username', 'total_games' ]
            },
            game_history: {
              type: :array,
              description: 'List of game sessions ordered by end date (most recent first)',
              items: {
                type: :object,
                properties: {
                  session_id: { type: :string, description: 'Unique session identifier' },
                  final_score: { type: :integer, description: 'Final score achieved' },
                  seed: { type: :integer, description: 'Random seed used for game generation' },
                  started_at: { type: :string, format: 'date-time', description: 'Game start timestamp' },
                  ended_at: { type: :string, format: 'date-time', description: 'Game end timestamp' },
                  game_duration: { type: :number, format: 'float', description: 'Game duration in seconds', nullable: true },
                  stats: {
                    type: :object,
                    properties: {
                      lilies_collected: { type: :integer, description: 'Number of lilies collected' },
                      obstacles_avoided: { type: :integer, description: 'Number of obstacles avoided' },
                      hearts_collected: { type: :integer, description: 'Number of hearts collected' },
                      max_speed_reached: { type: :number, format: 'float', description: 'Maximum speed reached' }
                    },
                    required: [ 'lilies_collected', 'obstacles_avoided', 'hearts_collected', 'max_speed_reached' ]
                  },
                  high_scores: {
                    type: :array,
                    description: 'High scores associated with this game session',
                    items: {
                      type: :object,
                      properties: {
                        id: { type: :integer, description: 'High score record ID' },
                        score: { type: :integer, description: 'Score value' },
                        player_name: { type: :string, description: 'Player name at time of score' },
                        created_at: { type: :string, format: 'date-time', description: 'When the score was recorded' }
                      },
                      required: [ 'id', 'score', 'player_name', 'created_at' ]
                    }
                  },
                  achievements_earned: { type: :integer, description: 'Number of achievements earned during this game' }
                },
                required: [ 'session_id', 'final_score', 'seed', 'started_at', 'ended_at', 'game_duration', 'stats', 'high_scores', 'achievements_earned' ]
              }
            },
            pagination: {
              type: :object,
              properties: {
                limit: { type: :integer, description: 'Number of results per page' },
                offset: { type: :integer, description: 'Current offset' },
                total: { type: :integer, description: 'Total number of completed games' },
                returned: { type: :integer, description: 'Number of games returned in this response' }
              },
              required: [ 'limit', 'offset', 'total', 'returned' ]
            }
          },
          required: [ 'player', 'game_history', 'pagination' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['player']['username']).to eq('testplayer')
          expect(data['player']['total_games']).to eq(2)
          expect(data['game_history'].length).to eq(2)
          expect(data['pagination']['total']).to eq(2)
          expect(data['pagination']['returned']).to eq(2)

          # Most recent game should be first
          expect(data['game_history'][0]['session_id']).to eq('session_2')
          expect(data['game_history'][0]['final_score']).to eq(2000)
          expect(data['game_history'][0]['achievements_earned']).to eq(1)

          # Older game should be second
          expect(data['game_history'][1]['session_id']).to eq('session_1')
          expect(data['game_history'][1]['final_score']).to eq(1000)
          expect(data['game_history'][1]['achievements_earned']).to eq(0)

          # Verify stats structure
          expect(data['game_history'][0]['stats']['lilies_collected']).to eq(20)
          expect(data['game_history'][0]['stats']['max_speed_reached']).to eq(75.3)

          # Verify high scores included
          expect(data['game_history'][0]['high_scores'].length).to eq(1)
          expect(data['game_history'][0]['high_scores'][0]['score']).to eq(2000)
        end
      end

      response(200, 'successful - with pagination') do
        let(:username) { player.username }
        let(:limit) { 1 }
        let(:offset) { 0 }
        let!(:game_sessions) do
          create_list(:game_session, 3, :completed, player: player)
        end

        schema type: :object,
          properties: {
            player: { type: :object },
            game_history: { type: :array },
            pagination: { type: :object }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['pagination']['limit']).to eq(1)
          expect(data['pagination']['offset']).to eq(0)
          expect(data['pagination']['total']).to eq(3)
          expect(data['pagination']['returned']).to eq(1)
          expect(data['game_history'].length).to eq(1)
        end
      end

      response(200, 'successful - no games') do
        let(:username) { player.username }

        schema type: :object,
          properties: {
            player: {
              type: :object,
              properties: {
                username: { type: :string },
                total_games: { type: :integer }
              }
            },
            game_history: { type: :array, items: {} },
            pagination: { type: :object }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['player']['username']).to eq('testplayer')
          expect(data['player']['total_games']).to eq(0)
          expect(data['game_history']).to eq([])
          expect(data['pagination']['total']).to eq(0)
          expect(data['pagination']['returned']).to eq(0)
        end
      end

      response(404, 'player not found') do
        let(:username) { 'nonexistent_player' }

        schema type: :object,
          properties: {
            errors: { type: :array, items: { type: :string } }
          },
          required: [ 'errors' ]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to include('Player not found')
        end
      end
    end
  end

  # Additional test cases not in Swagger docs
  describe 'GET /api/v1/players/:username/game-history' do
    context 'when player has incomplete game sessions' do
      it 'only returns completed game sessions' do
        create(:game_session, player: player, ended_at: nil, final_score: nil) # Incomplete
        create(:game_session, :completed, player: player, ended_at: 1.day.ago) # Completed

        get "/api/v1/players/#{player.username}/game-history"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['player']['total_games']).to eq(1)
        expect(data['game_history'].length).to eq(1)
      end
    end

    context 'when limit exceeds maximum' do
      it 'caps limit at 100' do
        get "/api/v1/players/#{player.username}/game-history?limit=200"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['pagination']['limit']).to eq(100)
      end
    end

    context 'when limit is zero or negative' do
      it 'defaults to 20' do
        get "/api/v1/players/#{player.username}/game-history?limit=0"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['pagination']['limit']).to eq(20)
      end
    end

    context 'when offset is provided' do
      it 'skips the specified number of games' do
        create_list(:game_session, 5, :completed, player: player).each_with_index do |session, i|
          session.update(session_id: "session_#{i}", ended_at: i.days.ago, final_score: 100 * i)
        end

        get "/api/v1/players/#{player.username}/game-history?limit=2&offset=2"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['pagination']['offset']).to eq(2)
        expect(data['pagination']['returned']).to eq(2)
        expect(data['game_history'].length).to eq(2)
        # Should skip the 2 most recent games
        expect(data['game_history'][0]['session_id']).to eq('session_2')
      end
    end

    context 'when game session has multiple high scores' do
      it 'returns all high scores for the session' do
        game_session = create(:game_session, :completed, player: player)
        create(:high_score, game_session: game_session)
        create(:high_score, game_session: game_session)

        get "/api/v1/players/#{player.username}/game-history"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['game_history'][0]['high_scores'].length).to eq(2)
      end
    end

    context 'when game session has multiple achievements' do
      it 'counts all achievements earned during the session' do
        game_session = create(:game_session, :completed, player: player)
        achievement1 = create(:achievement)
        achievement2 = create(:achievement)
        create(:earned_achievement, player: player, achievement: achievement1, game_session: game_session)
        create(:earned_achievement, player: player, achievement: achievement2, game_session: game_session)

        get "/api/v1/players/#{player.username}/game-history"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['game_history'][0]['achievements_earned']).to eq(2)
      end
    end

    context 'when games are ordered by ended_at' do
      it 'returns games in descending order by end time' do
        game1 = create(:game_session, :completed, player: player, session_id: 'oldest', ended_at: 5.days.ago)
        game2 = create(:game_session, :completed, player: player, session_id: 'middle', ended_at: 3.days.ago)
        game3 = create(:game_session, :completed, player: player, session_id: 'newest', ended_at: 1.day.ago)

        get "/api/v1/players/#{player.username}/game-history"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['game_history'].map { |g| g['session_id'] }).to eq(['newest', 'middle', 'oldest'])
      end
    end

    context 'when game_duration is nil' do
      it 'includes game_duration as null' do
        create(:game_session, :completed, player: player, started_at: 1.day.ago, ended_at: 1.day.ago, game_duration: nil)

        get "/api/v1/players/#{player.username}/game-history"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['game_history'][0]['game_duration']).to be_nil
      end
    end

    context 'when stats values are zero' do
      it 'includes zero values in stats' do
        create(:game_session, :completed,
               player: player,
               lilies_collected: 0,
               obstacles_avoided: 0,
               hearts_collected: 0,
               max_speed_reached: 0.0)

        get "/api/v1/players/#{player.username}/game-history"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        stats = data['game_history'][0]['stats']
        expect(stats['lilies_collected']).to eq(0)
        expect(stats['obstacles_avoided']).to eq(0)
        expect(stats['hearts_collected']).to eq(0)
        expect(stats['max_speed_reached']).to eq(0.0)
      end
    end
  end
end
