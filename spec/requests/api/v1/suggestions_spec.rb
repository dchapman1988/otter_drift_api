require 'swagger_helper'

RSpec.describe 'api/v1/suggestions', type: :request do
  path '/api/v1/suggestions' do
    post('Create Suggestion') do
      tags 'Suggestions'
      description 'Creates a new suggestion from a player or guest. Suggestions can be associated with a player by providing either player_name (username) or player_id.'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :suggestion, in: :body, schema: {
        type: :object,
        properties: {
          suggestion: {
            type: :object,
            properties: {
              note: {
                type: :string,
                description: 'The suggestion text (3-1000 characters)',
                minLength: 3,
                maxLength: 1000
              },
              player_name: {
                type: :string,
                description: 'Username of the player making the suggestion (optional)',
                nullable: true
              },
              player_id: {
                type: :integer,
                description: 'ID of the player making the suggestion (optional, player_name takes precedence)',
                nullable: true
              }
            },
            required: [ 'note' ]
          }
        },
        required: [ 'suggestion' ]
      }

      response(201, 'successful - suggestion created with player') do
        let!(:player) { create(:player, username: 'testplayer') }
        let(:suggestion) do
          {
            suggestion: {
              note: 'This is a great suggestion!',
              player_name: 'testplayer'
            }
          }
        end

        schema type: :object,
          properties: {
            id: { type: :integer, description: 'Suggestion ID' },
            note: { type: :string, description: 'Suggestion text' },
            player_id: { type: :integer, nullable: true, description: 'Associated player ID' },
            created_at: { type: :string, format: 'date-time', description: 'Creation timestamp' },
            updated_at: { type: :string, format: 'date-time', description: 'Last update timestamp' }
          },
          required: [ 'id', 'note', 'created_at', 'updated_at' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['note']).to eq('This is a great suggestion!')
          expect(data['player_id']).to eq(player.id)
          expect(Suggestion.count).to eq(1)
        end
      end

      response(201, 'successful - guest suggestion without player') do
        let(:suggestion) do
          {
            suggestion: {
              note: 'Guest suggestion from the community'
            }
          }
        end

        schema type: :object,
          properties: {
            id: { type: :integer, description: 'Suggestion ID' },
            note: { type: :string, description: 'Suggestion text' },
            player_id: { type: :integer, nullable: true, description: 'Associated player ID (null for guests)' },
            created_at: { type: :string, format: 'date-time', description: 'Creation timestamp' },
            updated_at: { type: :string, format: 'date-time', description: 'Last update timestamp' }
          },
          required: [ 'id', 'note', 'created_at', 'updated_at' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['note']).to eq('Guest suggestion from the community')
          expect(data['player_id']).to be_nil
          expect(Suggestion.count).to eq(1)
        end
      end

      response(422, 'unprocessable entity - invalid player name') do
        let(:suggestion) do
          {
            suggestion: {
              note: 'Great suggestion!',
              player_name: 'nonexistent_player'
            }
          }
        end

        schema type: :object,
          properties: {
            errors: {
              type: :object,
              description: 'Validation errors',
              properties: {
                player_name: {
                  type: :array,
                  items: { type: :string }
                }
              }
            }
          },
          required: [ 'errors' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']['player_name']).to be_present
          expect(data['errors']['player_name'].first).to include("Player with username 'nonexistent_player' not found")
          expect(Suggestion.count).to eq(0)
        end
      end

      response(422, 'unprocessable entity - missing note') do
        let(:suggestion) do
          {
            suggestion: {}
          }
        end

        schema type: :object,
          properties: {
            errors: {
              type: :object,
              description: 'Validation errors',
              additionalProperties: {
                type: :array,
                items: { type: :string }
              }
            }
          },
          required: [ 'errors' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to have_key('note')
          expect(Suggestion.count).to eq(0)
        end
      end

      response(422, 'unprocessable entity - note too short') do
        let(:suggestion) do
          {
            suggestion: {
              note: 'ok'
            }
          }
        end

        schema type: :object,
          properties: {
            errors: {
              type: :object,
              description: 'Validation errors',
              additionalProperties: {
                type: :array,
                items: { type: :string }
              }
            }
          },
          required: [ 'errors' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to have_key('note')
          expect(data['errors']['note'].first).to include('too short')
          expect(Suggestion.count).to eq(0)
        end
      end

      response(422, 'unprocessable entity - note too long') do
        let(:suggestion) do
          {
            suggestion: {
              note: 'a' * 1001
            }
          }
        end

        schema type: :object,
          properties: {
            errors: {
              type: :object,
              description: 'Validation errors',
              additionalProperties: {
                type: :array,
                items: { type: :string }
              }
            }
          },
          required: [ 'errors' ]

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to have_key('note')
          expect(data['errors']['note'].first).to include('too long')
          expect(Suggestion.count).to eq(0)
        end
      end
    end
  end
end
