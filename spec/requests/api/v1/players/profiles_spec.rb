require 'swagger_helper'

RSpec.describe 'api/v1/players/profiles', type: :request do
  let(:player) { create(:player, email: 'test@example.com', username: 'testuser', password: 'password123') }
  let(:auth_token) do
    post '/players/sign_in', params: { player: { email: player.email, password: 'password123' } }
    response.headers['Authorization']
  end
  let(:Authorization) { auth_token }

  path '/api/v1/players/profile' do
    get('Get Player Profile') do
      tags 'Player Profile'
      description 'Retrieves the authenticated player\'s profile information'
      security [ bearer_auth: [] ]
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            player: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                username: { type: :string },
                display_name: { type: :string, nullable: true },
                avatar_url: { type: :string, nullable: true },
                profile: {
                  type: :object,
                  properties: {
                    bio: { type: :string, nullable: true },
                    favorite_otter_fact: { type: :string, nullable: true },
                    title: { type: :string, nullable: true },
                    profile_banner_url: { type: :string, nullable: true },
                    location: { type: :string, nullable: true }
                  }
                }
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

    patch('Update Player Profile') do
      tags 'Player Profile'
      description 'Updates the authenticated player\'s profile and player information'
      security [ bearer_auth: [] ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :player_data, in: :body, schema: {
        type: :object,
        properties: {
          player: {
            type: :object,
            properties: {
              display_name: { type: :string, description: 'Player display name' },
              username: { type: :string, description: 'Player username (3-50 characters)' },
              email: { type: :string, description: 'Player email address' },
              avatar_url: { type: :string, description: 'URL to player avatar image' },
              profile: {
                type: :object,
                properties: {
                  bio: { type: :string, description: 'Player bio (max 500 characters)' },
                  favorite_otter_fact: { type: :string, description: 'Player\'s favorite otter fact (max 500 characters)' },
                  title: { type: :string, description: 'Player title (max 100 characters)' },
                  profile_banner_url: { type: :string, description: 'URL to profile banner image' },
                  location: { type: :string, description: 'Player location (max 100 characters)' }
                }
              }
            }
          }
        }
      }

      response(200, 'successful') do
        let(:player_data) do
          {
            player: {
              display_name: 'New Display Name',
              profile: {
                bio: 'I love otters!'
              }
            }
          }
        end

        schema type: :object,
          properties: {
            player: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                username: { type: :string },
                display_name: { type: :string },
                avatar_url: { type: :string, nullable: true },
                profile: {
                  type: :object,
                  properties: {
                    bio: { type: :string, nullable: true },
                    favorite_otter_fact: { type: :string, nullable: true },
                    title: { type: :string, nullable: true },
                    profile_banner_url: { type: :string, nullable: true },
                    location: { type: :string, nullable: true }
                  }
                }
              }
            },
            message: { type: :string }
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
        let(:Authorization) { nil }
        let(:player_data) do
          {
            player: {
              display_name: 'New Name'
            }
          }
        end

        schema type: :object,
          properties: {
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:player_data) do
          {
            player: {
              username: 'ab'  # Too short
            }
          }
        end

        schema type: :object,
          properties: {
            errors: { type: :array, items: { type: :string } },
            details: { type: :object, additionalProperties: true }
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
    end
  end
end
