require 'rails_helper'

RSpec.describe "Players::SessionsController", type: :request do
  let(:player) do
    create(:player,
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  describe "POST /players/sign_in" do
    context "with valid credentials" do
      it "returns success response with player data" do
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'password123'
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['player']).to be_present
        expect(json['player']['id']).to eq(player.id)
        expect(json['player']['email']).to eq(player.email)
        expect(json['player']['username']).to eq(player.username)
        expect(json['player']['display_name']).to eq(player.display_name_or_username)
        expect(json['player']['total_score']).to eq(player.total_score)
        expect(json['player']['games_played']).to eq(player.games_played)
        expect(json['message']).to eq('Logged in successfully.')
      end

      it "returns JWT token in Authorization header" do
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'password123'
          }
        }

        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to match(/^Bearer .+/)
      end
    end

    context "with invalid credentials" do
      it "returns error with invalid password" do
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'wrongpassword'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to eq([ 'Invalid email or password' ])
      end

      it "returns error with invalid email" do
        post '/players/sign_in', params: {
          player: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to eq([ 'Invalid email or password' ])
      end

      it "returns error with missing email" do
        post '/players/sign_in', params: {
          player: {
            password: 'password123'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to eq([ 'Invalid email or password' ])
      end

      it "returns error with missing password" do
        post '/players/sign_in', params: {
          player: {
            email: player.email
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to eq([ 'Invalid email or password' ])
      end
    end

    context "parameter handling" do
      it "handles missing player parameter gracefully" do
        post '/players/sign_in', params: {
          email: player.email,
          password: 'password123'
        }

        # Devise handles this gracefully by returning an error
        expect(response).to have_http_status(:bad_request)
      end

      it "filters out unpermitted parameters" do
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'password123',
            admin: true,
            role: 'superadmin'
          }
        }

        # Should succeed despite unpermitted params being present
        expect(response).to have_http_status(:ok)
      end
    end

    context "flash method override" do
      it "returns empty hash for flash to avoid flash messages in API" do
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'password123'
          }
        }

        # The response shouldn't contain flash-related data
        json = JSON.parse(response.body)
        expect(json).not_to have_key('flash')
      end
    end
  end

  describe "DELETE /players/sign_out" do
    context "with authenticated player" do
      it "returns success message" do
        # First sign in to get a token
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'password123'
          }
        }

        jwt_token = response.headers['Authorization']

        # Now sign out
        delete '/players/sign_out', headers: {
          'Authorization' => jwt_token
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Logged out successfully.')
      end

      it "revokes the JWT token" do
        # Sign in
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'password123'
          }
        }

        jwt_token = response.headers['Authorization']

        # Sign out
        delete '/players/sign_out', headers: {
          'Authorization' => jwt_token
        }

        expect(response).to have_http_status(:ok)

        # Verify token is revoked by trying to use it
        get '/api/v1/players/profile', headers: {
          'Authorization' => jwt_token
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without authentication" do
      it "returns unauthorized when no token provided" do
        delete '/players/sign_out'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['errors']).to eq([ 'No active session or invalid token.' ])
      end

      it "returns unauthorized when Authorization header format is invalid" do
        delete '/players/sign_out', headers: {
          'Authorization' => 'InvalidFormat'
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it "returns unauthorized when token is already revoked" do
        # Sign in
        post '/players/sign_in', params: {
          player: {
            email: player.email,
            password: 'password123'
          }
        }

        jwt_token = response.headers['Authorization']

        # Sign out once
        delete '/players/sign_out', headers: {
          'Authorization' => jwt_token
        }

        expect(response).to have_http_status(:ok)

        # Try to sign out again with same token
        delete '/players/sign_out', headers: {
          'Authorization' => jwt_token
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        # The error message from devise-jwt for revoked tokens
        expect(json['errors']).to be_present
      end
    end
  end

  describe "JSON response format" do
    it "responds to JSON requests" do
      post '/players/sign_in',
        params: {
          player: {
            email: player.email,
            password: 'password123'
          }
        },
        headers: { 'Accept' => 'application/json' }

      expect(response.content_type).to match(/application\/json/)
    end
  end

  describe "security: skip_before_action filters" do
    it "allows sign_in without authenticate_request" do
      # This test verifies that sign_in doesn't require authentication
      # (covered by successful sign_in tests above, but explicit check)
      post '/players/sign_in', params: {
        player: {
          email: player.email,
          password: 'password123'
        }
      }

      expect(response).to have_http_status(:ok)
    end
  end
end
