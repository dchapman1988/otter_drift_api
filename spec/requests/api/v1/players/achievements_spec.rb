require 'swagger_helper'

RSpec.describe 'api/v1/players/:username/achievements', type: :request do
  let(:player) { create(:player, username: 'testplayer') }

  path '/api/v1/players/{username}/achievements' do
    parameter name: :username, in: :path, type: :string, description: 'Player username'

    get('List Player Achievements') do
      tags 'Player Achievements'
      description 'Retrieves all achievements earned by a player, ordered by most recently collected'
      produces 'application/json'

      response(200, 'successful') do
        let(:username) { player.username }
        let!(:achievement1) do
          create(:lily_collector_achievement)
        end
        let!(:achievement2) do
          create(:achievement,
                 achievement_type: 'speed_demon',
                 name: 'Speed Demon',
                 icon_url: nil) # No icon_url to test emoji fallback
        end
        let!(:earned_achievement1) do
          create(:earned_achievement,
                 player: player,
                 achievement: achievement1,
                 earned_at: 2.days.ago)
        end
        let!(:earned_achievement2) do
          create(:earned_achievement,
                 player: player,
                 achievement: achievement2,
                 earned_at: 1.day.ago)
        end

        schema type: :object,
          properties: {
            username: { type: :string, description: 'Player username' },
            total_achievements: { type: :integer, description: 'Total number of achievements earned' },
            achievements: {
              type: :array,
              description: 'List of achievements ordered by collection date (most recent first)',
              items: {
                type: :object,
                properties: {
                  name: { type: :string, description: 'Achievement name' },
                  description: { type: :string, description: 'Achievement description' },
                  achievement_type: { type: :string, description: 'Unique achievement type identifier' },
                  points: { type: :integer, description: 'Points awarded for this achievement' },
                  badge_url: { type: :string, description: 'Badge URL if available, otherwise an emoji fallback' },
                  collected_at: { type: :string, format: 'date-time', description: 'When the achievement was earned' }
                },
                required: [ 'name', 'description', 'achievement_type', 'points', 'badge_url', 'collected_at' ]
              }
            }
          },
          required: [ 'username', 'total_achievements', 'achievements' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['username']).to eq('testplayer')
          expect(data['total_achievements']).to eq(2)
          expect(data['achievements'].length).to eq(2)

          # Most recent achievement should be first
          expect(data['achievements'][0]['achievement_type']).to eq('speed_demon')
          expect(data['achievements'][0]['badge_url']).to eq('⚡') # Emoji fallback

          # Second achievement should have icon_url as badge_url
          expect(data['achievements'][1]['achievement_type']).to eq('lily_collector')
          expect(data['achievements'][1]['badge_url']).to eq('https://example.com/lily.png')
        end
      end

      response(200, 'successful - no achievements') do
        let(:username) { player.username }

        schema type: :object,
          properties: {
            username: { type: :string },
            total_achievements: { type: :integer },
            achievements: { type: :array, items: {} }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['username']).to eq('testplayer')
          expect(data['total_achievements']).to eq(0)
          expect(data['achievements']).to eq([])
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
  describe 'GET /api/v1/players/:username/achievements' do
    context 'when achievement has blank icon_url' do
      it 'returns default emoji fallback' do
        achievement = create(:achievement, achievement_type: 'unknown_type', icon_url: '')
        create(:earned_achievement, player: player, achievement: achievement)

        get "/api/v1/players/#{player.username}/achievements"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['achievements'][0]['badge_url']).to eq('🏅') # Default emoji
      end
    end

    context 'when achievement type has emoji mapping' do
      it 'returns the correct emoji for heart_hoarder' do
        achievement = create(:heart_hoarder_achievement, icon_url: nil)
        create(:earned_achievement, player: player, achievement: achievement)

        get "/api/v1/players/#{player.username}/achievements"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['achievements'][0]['badge_url']).to eq('💖')
      end

      it 'returns the correct emoji for lily_collector when icon_url is blank' do
        achievement = create(:lily_collector_achievement, icon_url: '')
        create(:earned_achievement, player: player, achievement: achievement)

        get "/api/v1/players/#{player.username}/achievements"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['achievements'][0]['badge_url']).to eq('🌸')
      end
    end

    context 'when player has multiple achievements' do
      it 'orders them by earned_at descending' do
        achievement1 = create(:achievement, name: 'First')
        achievement2 = create(:achievement, name: 'Second')
        achievement3 = create(:achievement, name: 'Third')

        create(:earned_achievement, player: player, achievement: achievement1, earned_at: 3.days.ago)
        create(:earned_achievement, player: player, achievement: achievement2, earned_at: 1.day.ago)
        create(:earned_achievement, player: player, achievement: achievement3, earned_at: 2.days.ago)

        get "/api/v1/players/#{player.username}/achievements"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['achievements'].map { |a| a['name'] }).to eq([ 'Second', 'Third', 'First' ])
      end
    end

    context 'when player has achievements with and without icon_urls' do
      it 'returns correct badge_url for each' do
        achievement_with_url = create(:achievement, icon_url: 'https://example.com/badge.png')
        achievement_without_url = create(:achievement, achievement_type: 'speed_demon', icon_url: nil)

        create(:earned_achievement, player: player, achievement: achievement_with_url, earned_at: 2.days.ago)
        create(:earned_achievement, player: player, achievement: achievement_without_url, earned_at: 1.day.ago)

        get "/api/v1/players/#{player.username}/achievements"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)

        expect(data['achievements'][0]['badge_url']).to eq('⚡') # Emoji fallback
        expect(data['achievements'][1]['badge_url']).to eq('https://example.com/badge.png') # URL
      end
    end
  end
end
