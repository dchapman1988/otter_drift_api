require 'swagger_helper'

RSpec.describe 'api/v1/players/stats', type: :request do
  let(:player) { create(:player, email: 'test@example.com', username: 'testuser', password: 'password123') }
  let(:auth_token) do
    post '/players/sign_in', params: { player: { email: player.email, password: 'password123' } }
    response.headers['Authorization']
  end
  let(:Authorization) { auth_token }

  path '/api/v1/players/stats' do
    get('Get Player Stats') do
      tags 'Player Stats'
      description 'Retrieves the authenticated player\'s game statistics'
      security [ bearer_auth: [] ]
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            player_stats: {
              type: :object,
              properties: {
                total_score: { type: :integer, description: 'Total cumulative score across all games' },
                games_played: { type: :integer, description: 'Total number of games played' },
                personal_best: { type: :integer, description: 'Highest score in a single game' }
              }
            }
          }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(401, 'unauthorized') do
        schema type: :object,
          properties: {
            errors: { type: :array, items: { type: :string } }
          }

        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
